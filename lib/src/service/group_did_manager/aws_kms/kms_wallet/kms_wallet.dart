import 'dart:convert';
import 'dart:typed_data';

import 'package:aws_kms_api/kms-2014-11-01.dart' as kms;
import 'package:aws_sts_api/sts-2011-06-15.dart' as sts;
import 'package:ssi/ssi.dart';

import '../../../credentials_manager/aws_credentials_manager.dart';
import '../../../../core/config/env_config.dart';
import 'stores/kms_key_store.dart';
import 'kms_wrapper.dart';
import 'kms_key_pair.dart';
import 'kms_wallet_exception.dart';

enum KeyUsage { encryptDecrypt, signingVerify, keyAgreement }

const _keyUsageToKmsKeyUsageType = {
  KeyUsage.signingVerify: KeyUsageTypeExtension.signVerify,
  KeyUsage.keyAgreement: KeyUsageTypeExtension.keyAgreement,
};

KeyUsageTypeExtension keyUsageTypeForKms(KeyUsage keyUsage) {
  return _keyUsageToKmsKeyUsageType[keyUsage] ??
      (throw KmsWalletException.unsupportedKeyUsageType(keyUsage: keyUsage));
}

const _keyTypeToKmsCustomerMasterKeySpec = {
  KeyType.p256: kms.CustomerMasterKeySpec.eccNistP256,
  KeyType.p384: kms.CustomerMasterKeySpec.eccNistP384,
  KeyType.p521: kms.CustomerMasterKeySpec.eccNistP521,
  KeyType.secp256k1: kms.CustomerMasterKeySpec.eccSecgP256k1,
};

kms.CustomerMasterKeySpec keyTypeForKms(KeyType keyType) {
  return _keyTypeToKmsCustomerMasterKeySpec[keyType] ??
      (throw KmsWalletException.unsupportedKeyType(keyType: keyType));
}

class KmsWallet implements Wallet {
  KmsWallet._({
    required KMSWrapper kmsClient,
    required sts.STS stsClient,
    required KMSKeyStore store,
    required String roleArn,
    required String deploymentId,
    required kms.AwsClientCredentials credentials,
  })  : _kmsClient = kmsClient,
        _stsClient = stsClient,
        _store = store,
        _roleArn = roleArn,
        _deploymentId = deploymentId,
        _credentials = credentials;

  KMSWrapper _kmsClient;
  sts.STS _stsClient;
  kms.AwsClientCredentials _credentials;

  final KMSKeyStore _store;
  final String _roleArn;
  final String _deploymentId;

  static init({
    required KMSKeyStore store,
    required String roleArn,
    required String deploymentId,
  }) async {
    final region = getEnv('AWS_REGION');
    final credentials = await AwsCredentialsManager.getCredentials();

    final kmsClient = KMSWrapper(
      inner: kms.KMS(region: region, credentials: credentials),
      region: region,
      credentials: credentials,
    );

    final stsClient = sts.STS(region: region, credentials: credentials);

    return KmsWallet._(
      kmsClient: kmsClient,
      stsClient: stsClient,
      store: store,
      roleArn: roleArn,
      deploymentId: deploymentId,
      credentials: credentials,
    );
  }

  @override
  Future<Uint8List> sign(
    Uint8List data, {
    required String keyId,
    SignatureScheme? signatureScheme,
  }) async {
    final keyPair = await getKeyPair(keyId);
    return keyPair.sign(data, signatureScheme: signatureScheme);
  }

  @override
  Future<bool> verify(
    Uint8List data, {
    required Uint8List signature,
    required String keyId,
    SignatureScheme? signatureScheme,
  }) async {
    final keyPair = await getKeyPair(keyId);
    return keyPair.verify(data, signature, signatureScheme: signatureScheme);
  }

  @override
  Future<List<SignatureScheme>> getSupportedSignatureSchemes(
      String keyId) async {
    final keyPair = await getKeyPair(keyId);
    return keyPair.supportedSignatureSchemes;
  }

  @override
  Future<PublicKey> getPublicKey(String keyId) async {
    final keyPair = await getKeyPair(keyId);
    final keyData = keyPair.publicKey;
    return Future.value(PublicKey(keyId, keyData.bytes, keyData.type));
  }

  Future<bool> hasKey(String keyId) async {
    try {
      final kmsClient = await _getKMSClient();
      await kmsClient.describeKey(keyId: keyId);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<KeyPair> generateKey({
    String? keyId,
    KeyType? keyType,
    KeyUsage? keyUsage,
  }) async {
    final kmsClient = await _getKMSClient();

    if (keyId != null && await _store.contains(keyId)) {
      return KmsKeyPair.createFromStore(_store,
          kmsClient: kmsClient, keyId: keyId);
    }

    if (keyId != null) {
      final keyPair = await KmsKeyPair.create(kmsClient, keyId);
      final storedKmsKey = StoredKmsKey(
        id: keyPair.id,
        publicKeyBytes: keyPair.publicKey.bytes,
      );
      await _store.set(keyPair.id, storedKmsKey);
      return keyPair;
    }

    if (keyType == null) {
      throw ArgumentError('keyType is required for KmsWallet');
    }

    if (keyUsage == null) {
      throw ArgumentError(
          '''keyUsage is required for KmsWallet as it defines usage type of KMS key''');
    }

    final stsClient = await _getStsClient();
    final identity = await stsClient.getCallerIdentity();
    if (identity.account == null) {
      throw KmsWalletException.awsAccountIdMissing();
    }

    final response = await kmsClient.createKey(
      keyUsageExtension: keyUsageTypeForKms(keyUsage),
      customerMasterKeySpec: keyTypeForKms(keyType),
      policy: jsonEncode({
        "Version": "2012-10-17",
        "Statement": [
          {
            "Sid": "EnableRootAccount",
            "Effect": "Allow",
            "Principal": {"AWS": "arn:aws:iam::${identity.account}:root"},
            "Action": ["kms:*"],
            "Resource": "*",
          },
          {
            "Sid": "AllowFargateTaskToUse",
            "Effect": "Allow",
            "Principal": {"AWS": _roleArn},
            "Action": _getPolicyActionsByKeyUsage(keyUsage),
            "Resource": "*"
          },
        ],
      }),
      tags: [
        kms.Tag(tagKey: 'deploymentId', tagValue: _deploymentId),
        kms.Tag(tagKey: 'service', tagValue: 'mpx')
      ],
    );

    final generatedKeyId = response.keyMetadata?.keyId;
    if (generatedKeyId == null) {
      throw Exception('Empty key id returned by create key operation');
    }

    final keyPair = await KmsKeyPair.create(kmsClient, generatedKeyId);

    final storedKmsKey = StoredKmsKey(
      id: generatedKeyId,
      publicKeyBytes: keyPair.publicKey.bytes,
    );
    await _store.set(generatedKeyId, storedKmsKey);
    return keyPair;
  }

  @override
  Future<Uint8List> encrypt(
    Uint8List data, {
    required String keyId,
    Uint8List? publicKey,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Uint8List> decrypt(
    Uint8List data, {
    required String keyId,
    Uint8List? publicKey,
  }) async {
    throw UnimplementedError();
  }

  Future<KmsKeyPair> getKeyPair(String keyId) async {
    final client = await _getKMSClient();
    if (await _store.contains(keyId)) {
      return KmsKeyPair.createFromStore(_store,
          kmsClient: client, keyId: keyId);
    }
    return KmsKeyPair.create(client, keyId);
  }

  Future<void> deleteKeyPair(String keyId) async {
    final client = await _getKMSClient();
    await client.scheduleKeyDeletion(keyId: keyId, pendingWindowInDays: 7);
  }

  List<String> _getPolicyActionsByKeyUsage(KeyUsage keyUsage) {
    return ['kms:*'];
    // if (keyUsage == KeyUsage.keyAgreement) {
    //   // return ['kms:DeriveKey', 'kms:ScheduleKeyDeletion'];
    // }

    // if (keyUsage == KeyUsage.signingVerify) {
    //   return ['kms:Sign', 'kms:DescribeKey', 'kms:ScheduleKeyDeletion'];
    // }

    // throw KmsWalletException.keyUsageNotSupported(keyUsage: keyUsage);
  }

  Future<KMSWrapper> _getKMSClient() async {
    final refreshedCredentials =
        await AwsCredentialsManager.refreshCredentialsIfNeeded(_credentials);

    if (refreshedCredentials != null) {
      final region = getEnv('AWS_REGION');
      _credentials = refreshedCredentials;
      _kmsClient = KMSWrapper(
        inner: kms.KMS(region: region, credentials: refreshedCredentials),
        region: region,
        credentials: refreshedCredentials,
      );
    }
    return _kmsClient;
  }

  Future<sts.STS> _getStsClient() async {
    final refreshedCredentials =
        await AwsCredentialsManager.refreshCredentialsIfNeeded(_credentials);

    if (refreshedCredentials != null) {
      _credentials = refreshedCredentials;
      _stsClient = sts.STS(
        region: getEnv('AWS_REGION'),
        credentials: refreshedCredentials,
      );
    }
    return _stsClient;
  }
}
