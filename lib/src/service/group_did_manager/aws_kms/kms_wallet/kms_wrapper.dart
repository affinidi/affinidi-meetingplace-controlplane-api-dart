import 'dart:typed_data';
import 'package:aws_kms_api/kms-2014-11-01.dart';
import 'package:shared_aws_api/shared.dart' as s;

enum KeyAgreementAlgorithm {
  ecdh('ECDH');

  const KeyAgreementAlgorithm(this.value);

  final String value;
}

enum KeyUsageTypeExtension { signVerify, encryptDecrypt, keyAgreement }

extension KeyUsageTypeValueExtension on KeyUsageTypeExtension {
  String toValue() {
    switch (this) {
      case KeyUsageTypeExtension.signVerify:
        return 'SIGN_VERIFY';
      case KeyUsageTypeExtension.encryptDecrypt:
        return 'ENCRYPT_DECRYPT';
      case KeyUsageTypeExtension.keyAgreement:
        return 'KEY_AGREEMENT';
    }
  }
}

class KMSWrapper implements KMS {
  KMSWrapper({
    required KMS inner,
    required String region,
    s.AwsClientCredentials? credentials,
    s.AwsClientCredentialsProvider? credentialsProvider,
    s.Client? client,
    String? endpointUrl,
  }) : _inner = inner,
       _wrapperProtocol = s.JsonProtocol(
         service: s.ServiceMetadata(endpointPrefix: 'kms'),
         region: region,
         credentials: credentials,
         credentialsProvider: credentialsProvider,
         endpointUrl: endpointUrl,
       );
  final s.JsonProtocol _wrapperProtocol;

  final Map<String, s.AwsExceptionFn> _exceptionMap = {
    'KMSInternalException': (type, message) =>
        KMSInternalException(type: type, message: message),
    'KMSInvalidSignatureException': (type, message) =>
        KMSInvalidSignatureException(type: type, message: message),
    'KMSInvalidStateException': (type, message) =>
        KMSInvalidStateException(type: type, message: message),
  };

  final KMS _inner;

  Future<Map<String, dynamic>> deriveKey({
    required String keyId,
    required String publicKey,
    KeyAgreementAlgorithm keyAgreementAlg = KeyAgreementAlgorithm.ecdh,
  }) async {
    ArgumentError.checkNotNull(keyId, 'keyId');
    s.validateStringLength('keyId', keyId, 1, 2048, isRequired: true);

    final headers = <String, String>{
      'Content-Type': 'application/x-amz-json-1.1',
      'X-Amz-Target': 'TrentService.DeriveSharedSecret',
    };

    final jsonResponse = await _wrapperProtocol.send(
      method: 'POST',
      requestUri: '/',
      exceptionFnMap: _exceptionMap,
      headers: headers,
      payload: {
        'KeyId': keyId,
        'KeyAgreementAlgorithm': keyAgreementAlg.value,
        'PublicKey': publicKey,
      },
    );

    return jsonResponse.body;
  }

  @override
  Future<CreateKeyResponse> createKey({
    bool? bypassPolicyLockoutSafetyCheck,
    String? customKeyStoreId,
    CustomerMasterKeySpec? customerMasterKeySpec,
    String? description,
    KeyUsageType? keyUsage,
    KeyUsageTypeExtension? keyUsageExtension,
    OriginType? origin,
    String? policy,
    List<Tag>? tags,
  }) async {
    s.validateStringLength('customKeyStoreId', customKeyStoreId, 1, 64);
    s.validateStringLength('description', description, 0, 8192);
    s.validateStringLength('policy', policy, 1, 131072);
    final headers = <String, String>{
      'Content-Type': 'application/x-amz-json-1.1',
      'X-Amz-Target': 'TrentService.CreateKey',
    };
    final jsonResponse = await _wrapperProtocol.send(
      method: 'POST',
      requestUri: '/',
      exceptionFnMap: _exceptionMap,
      headers: headers,
      payload: {
        if (bypassPolicyLockoutSafetyCheck != null)
          'BypassPolicyLockoutSafetyCheck': bypassPolicyLockoutSafetyCheck,
        if (customKeyStoreId != null) 'CustomKeyStoreId': customKeyStoreId,
        if (customerMasterKeySpec != null)
          'CustomerMasterKeySpec': customerMasterKeySpec.toValue(),
        if (description != null) 'Description': description,
        if (keyUsageExtension != null) 'KeyUsage': keyUsageExtension.toValue(),
        if (origin != null) 'Origin': origin.toValue(),
        if (policy != null) 'Policy': policy,
        if (tags != null) 'Tags': tags,
      },
    );

    return CreateKeyResponse(
      keyMetadata: KeyMetadata(
        keyId: jsonResponse.body['KeyMetadata']['KeyId'],
      ),
    );
  }

  @override
  Future<GetPublicKeyResponse> getPublicKey({
    required String keyId,
    List<String>? grantTokens,
  }) async {
    ArgumentError.checkNotNull(keyId, 'keyId');
    s.validateStringLength('keyId', keyId, 1, 2048, isRequired: true);
    final headers = <String, String>{
      'Content-Type': 'application/x-amz-json-1.1',
      'X-Amz-Target': 'TrentService.GetPublicKey',
    };
    final jsonResponse = await _wrapperProtocol.send(
      method: 'POST',
      requestUri: '/',
      exceptionFnMap: _exceptionMap,
      headers: headers,
      payload: {
        'KeyId': keyId,
        if (grantTokens != null) 'GrantTokens': grantTokens,
      },
    );

    return GetPublicKeyResponse(
      customerMasterKeySpec:
          (jsonResponse.body['CustomerMasterKeySpec'] as String?)
              ?.toCustomerMasterKeySpec(),
      publicKey: s.decodeNullableUint8List(
        jsonResponse.body['PublicKey'] as String?,
      ),
    );
  }

  @override
  Future<SignResponse> sign({
    required String keyId,
    required Uint8List message,
    required SigningAlgorithmSpec signingAlgorithm,
    bool? dryRun,
    List<String>? grantTokens,
    MessageType? messageType,
  }) {
    return _inner.sign(
      keyId: keyId,
      message: message,
      signingAlgorithm: signingAlgorithm,
      grantTokens: grantTokens,
      messageType: messageType,
    );
  }

  @override
  Future<ScheduleKeyDeletionResponse> scheduleKeyDeletion({
    required String keyId,
    int? pendingWindowInDays,
  }) {
    return _inner.scheduleKeyDeletion(
      keyId: keyId,
      pendingWindowInDays: pendingWindowInDays,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
