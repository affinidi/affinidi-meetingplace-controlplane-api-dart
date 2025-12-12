import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'response_error_model.g.dart';

enum AuthAuthenticateErrorCodes {
  invalidChallengeResponse('INVALID_CHALLENGE_RESPONSE');

  const AuthAuthenticateErrorCodes(this.value);

  final String value;
}

@JsonSerializable()
class AuthAuthenticateErrorResponse {
  AuthAuthenticateErrorResponse({
    required this.errorCode,
    required this.error,
    required this.issue,
  });

  factory AuthAuthenticateErrorResponse.invalidChallengeResponse(String issue) {
    return AuthAuthenticateErrorResponse(
      errorCode: AuthAuthenticateErrorCodes.invalidChallengeResponse.value,
      error: 'Invalid challenge response',
      issue: issue,
    );
  }
  final String errorCode;
  final String error;
  final String issue;

  @override
  String toString() =>
      JsonEncoder().convert(_$AuthAuthenticateErrorResponseToJson(this));
}
