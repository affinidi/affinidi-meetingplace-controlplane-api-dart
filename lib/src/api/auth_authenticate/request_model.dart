import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

import '../request_validation_exception.dart';
import 'request_validator.dart';

part 'request_model.g.dart';

@JsonSerializable()
class AuthAuthenticateRequest {
  AuthAuthenticateRequest({required this.challengeResponse});

  factory AuthAuthenticateRequest.fromRequestParams(String requestParams) {
    final params = jsonDecode(requestParams);

    final validationResult = AuthAuthenticateRequestValidator().validate(
      params,
    );

    if (!validationResult.isValid) {
      throw RequestValidationException.fromValidationResult(validationResult);
    }

    return _$AuthAuthenticateRequestFromJson(params);
  }
  @JsonKey(name: 'challenge_response')
  final String challengeResponse;
}
