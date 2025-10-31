import 'package:aws_kms_api/kms-2014-11-01.dart';
import 'package:ssi/ssi.dart';

import 'kms_wallet.dart';

enum KmsWalletExceptionCodes {
  generic('generic'),
  unsupportedKeyUsageType('unsupported_key_usage_type'),
  unsupportedKeyType('unsupported_key_type'),
  unsupportedSignatureScheme('unsupported_signature_scheme'),
  kmsCustomerKeySpecMissing('kms_customer_key_spec_missing'),
  derCodingForKmsCustomerKeySpecUnImplemented(
      'der_decoding_for_kms_customer_key_spec_un_implemented'),
  keyNotFound('key_not_found'),
  keyReferenceNotFound('key_reference_not_found'),
  keyUsageNotSupported('key_usage_not_supported'),
  awsAccountIdMissing('aws_account_id_missing');

  const KmsWalletExceptionCodes(this.code);

  final String code;
}

class KmsWalletException implements Exception {
  factory KmsWalletException.generic({
    Object? originalException,
  }) {
    return KmsWalletException(
      message: 'KMS wallet exception: ${originalException.toString()}.',
      code: KmsWalletExceptionCodes.generic,
      originalException: originalException,
    );
  }

  factory KmsWalletException.unsupportedKeyUsageType({
    required KeyUsage keyUsage,
    Object? originalException,
  }) {
    return KmsWalletException(
      message:
          'KMS wallet exception: unsupported key usage type: ${keyUsage.name}',
      code: KmsWalletExceptionCodes.unsupportedKeyUsageType,
      originalException: originalException,
    );
  }

  factory KmsWalletException.unsupportedKeyType({
    required KeyType keyType,
    Object? originalException,
  }) {
    return KmsWalletException(
      message: 'KMS wallet exception: unsupported key type: ${keyType.name}',
      code: KmsWalletExceptionCodes.unsupportedKeyType,
      originalException: originalException,
    );
  }

  factory KmsWalletException.missingKmsCustomerKeySpec({
    Object? originalException,
  }) {
    return KmsWalletException(
      message: 'KMS wallet exception: KMS customer key spec missing',
      code: KmsWalletExceptionCodes.kmsCustomerKeySpecMissing,
      originalException: originalException,
    );
  }

  factory KmsWalletException.derDecodingForKmsCustomerKeySpecUnimplemented({
    required CustomerMasterKeySpec spec,
    Object? originalException,
  }) {
    return KmsWalletException(
      message:
          '''KMS wallet exception: unimplemented supported for DER decoding of key spec ${spec.toValue()}''',
      code: KmsWalletExceptionCodes.derCodingForKmsCustomerKeySpecUnImplemented,
      originalException: originalException,
    );
  }

  factory KmsWalletException.unsupportedSignatureScheme({
    required SignatureScheme scheme,
    Object? originalException,
  }) {
    return KmsWalletException(
      message:
          '''KMS wallet exception: unsupported signature scheme ${scheme.name}''',
      code: KmsWalletExceptionCodes.unsupportedSignatureScheme,
      originalException: originalException,
    );
  }

  factory KmsWalletException.keyNotFound({
    required String keyId,
    Object? originalException,
  }) {
    return KmsWalletException(
      message: 'KMS wallet exception: key not found $keyId',
      code: KmsWalletExceptionCodes.keyNotFound,
      originalException: originalException,
    );
  }

  factory KmsWalletException.keyReferenceNotFound({
    required String keyReferenceId,
    Object? originalException,
  }) {
    return KmsWalletException(
      message: 'KMS wallet exception: key reference not found $keyReferenceId',
      code: KmsWalletExceptionCodes.keyReferenceNotFound,
      originalException: originalException,
    );
  }

  factory KmsWalletException.keyUsageNotSupported({
    required KeyUsage keyUsage,
    Object? originalException,
  }) {
    return KmsWalletException(
      message:
          'KMS wallet exception: key usage type not supported ${keyUsage.name}',
      code: KmsWalletExceptionCodes.keyUsageNotSupported,
      originalException: originalException,
    );
  }

  factory KmsWalletException.awsAccountIdMissing({
    Object? originalException,
  }) {
    return KmsWalletException(
      message: 'KMS wallet exception: missing AWS account id',
      code: KmsWalletExceptionCodes.awsAccountIdMissing,
      originalException: originalException,
    );
  }

  KmsWalletException({
    required this.message,
    required this.code,
    required this.originalException,
  });
  final String message;

  final KmsWalletExceptionCodes code;
  final Object? originalException;

  String get errorCode => code.code;
}
