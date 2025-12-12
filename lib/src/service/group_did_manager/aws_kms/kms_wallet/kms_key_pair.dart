import 'dart:convert';
import 'dart:typed_data';

import 'package:aws_kms_api/kms-2014-11-01.dart' as kms;
import 'package:pointycastle/export.dart' hide PublicKey;
import 'package:ssi/ssi.dart';

import 'utils/der_decoder.dart';
import 'stores/kms_key_store.dart';
import 'kms_wrapper.dart';
import 'kms_wallet_exception.dart';
import 'utils/kms_key_pair_utils_p256.dart';

const _signatureSchemeToKmsAlgorithm = {
  SignatureScheme.ecdsa_p256_sha256: kms.SigningAlgorithmSpec.ecdsaSha_256,
};

kms.SigningAlgorithmSpec signingAlgorithmForScheme(SignatureScheme scheme) {
  return _signatureSchemeToKmsAlgorithm[scheme] ??
      (throw KmsWalletException.unsupportedSignatureScheme(scheme: scheme));
}

const _supportedKeyTypesForDerDecoding = [
  kms.CustomerMasterKeySpec.eccNistP256,
];

class KmsKeyPair implements KeyPair {
  KmsKeyPair._(this.kmsClient, this.id, this._publicKeyBytes);
  final KMSWrapper kmsClient;
  @override
  final String id;
  final Uint8List _publicKeyBytes;

  static Future<KmsKeyPair> create(KMSWrapper kmsClient, String id) async {
    final response = await kmsClient.getPublicKey(keyId: id);
    final publicKey = response.publicKey;
    final kmsMasterKeySpec = response.customerMasterKeySpec;

    if (publicKey == null) {
      throw KmsWalletException.keyNotFound(keyId: id);
    }

    if (kmsMasterKeySpec == null) {
      throw KmsWalletException.missingKmsCustomerKeySpec();
    }

    if (!_supportedKeyTypesForDerDecoding.contains(kmsMasterKeySpec)) {
      throw KmsWalletException.derDecodingForKmsCustomerKeySpecUnimplemented(
        spec: kmsMasterKeySpec,
        originalException: UnimplementedError(),
      );
    }

    final publicKeyBytes = KmsKeyPairUtilsP256.kmsP256ToEllipticFormat(
      publicKey,
      kmsMasterKeySpec.toValue(),
    );

    return KmsKeyPair._(kmsClient, id, publicKeyBytes);
  }

  static Future<KmsKeyPair> createFromStore(
    KMSKeyStore store, {
    required KMSWrapper kmsClient,
    required String keyId,
  }) async {
    final key = await store.get(keyId);
    if (key == null) {
      throw KmsWalletException.keyNotFound(keyId: keyId);
    }
    return KmsKeyPair._(kmsClient, keyId, key.publicKeyBytes);
  }

  @override
  List<SignatureScheme> get supportedSignatureSchemes => [
    SignatureScheme.ecdsa_p256_sha256,
  ];

  @override
  SignatureScheme get defaultSignatureScheme =>
      SignatureScheme.ecdsa_p256_sha256;

  @override
  PublicKey get publicKey {
    return PublicKey(id, _publicKeyBytes, KeyType.p256);
  }

  @override
  Future<Uint8List> sign(
    Uint8List data, {
    SignatureScheme? signatureScheme,
  }) async {
    if (signatureScheme == null) {
      throw ArgumentError('Signature scheme is required for KmsKeyPair');
    }

    if (signatureScheme != SignatureScheme.ecdsa_p256_sha256) {
      throw SsiException(
        message:
            '''Unsupported signature scheme. Currently only RSA is supported with SHA256''',
        code: SsiExceptionType.unsupportedSignatureScheme.code,
      );
    }

    final digest = SHA256Digest();
    final messageHash = digest.process(data);

    final response = await kmsClient.sign(
      keyId: id,
      message: messageHash,
      messageType: kms.MessageType.digest,
      signingAlgorithm: signingAlgorithmForScheme(signatureScheme),
    );

    return DerDecoder.convert(response.signature!, 32);
  }

  @override
  Future<bool> verify(
    Uint8List data,
    Uint8List signature, {
    SignatureScheme? signatureScheme,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Uint8List> encrypt(Uint8List data, {Uint8List? publicKey}) async {
    throw UnimplementedError();
  }

  @override
  Future<Uint8List> decrypt(Uint8List data, {Uint8List? publicKey}) async {
    throw UnimplementedError();
  }

  /// Computes the Elliptic Curve Diffie-Hellman (ECDH) shared secret.
  ///
  /// [publicKey] - The public key of the other party (in compressed format).
  ///
  /// Returns the computed shared secret as a [Uint8List].
  @override
  Future<Uint8List> computeEcdhSecret(Uint8List publicKey) async {
    final kmsPublicKey = KmsKeyPairUtilsP256.formatForAWSKMS(
      KmsKeyPairUtilsP256.uncompressPublicKey(publicKey),
    );

    final response = await kmsClient.deriveKey(
      keyId: id,
      publicKey: kmsPublicKey,
    );

    return Uint8List.fromList(base64Decode(response['SharedSecret'] as String));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}
