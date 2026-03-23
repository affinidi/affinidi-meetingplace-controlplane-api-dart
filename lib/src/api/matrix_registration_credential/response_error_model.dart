import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'response_error_model.g.dart';

enum MatrixRegistrationCredentialErrorCodes {
  invalidChallengeResponse('INVALID_CHALLENGE_RESPONSE'),
  invalidHomeserver('INVALID_HOMESERVER');

  const MatrixRegistrationCredentialErrorCodes(this.value);
  final String value;
}

@JsonSerializable()
class MatrixRegistrationCredentialErrorResponse {
  MatrixRegistrationCredentialErrorResponse({
    required this.errorCode,
    required this.error,
    required this.issue,
  });

  factory MatrixRegistrationCredentialErrorResponse.invalidChallengeResponse(
    String issue,
  ) {
    return MatrixRegistrationCredentialErrorResponse(
      errorCode:
          MatrixRegistrationCredentialErrorCodes.invalidChallengeResponse.value,
      error: 'Invalid challenge response',
      issue: issue,
    );
  }

  factory MatrixRegistrationCredentialErrorResponse.invalidHomeserver(
    String issue,
  ) {
    return MatrixRegistrationCredentialErrorResponse(
      errorCode: MatrixRegistrationCredentialErrorCodes.invalidHomeserver.value,
      error: 'Invalid homeserver',
      issue: issue,
    );
  }

  final String errorCode;
  final String error;
  final String issue;

  @override
  String toString() => JsonEncoder().convert(
        _$MatrixRegistrationCredentialErrorResponseToJson(this),
      );
}
