import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

import '../request_validation_exception.dart';
import 'request_validator.dart';

part 'request_model.g.dart';

@JsonSerializable()
class AuthChallengeRequest {
  AuthChallengeRequest({required this.did});

  factory AuthChallengeRequest.fromRequestParams(String requestParams) {
    final params = jsonDecode(requestParams);

    final validationResult = AuthChallengeRequestValidator().validate(params);

    if (!validationResult.isValid) {
      throw RequestValidationException.fromValidationResult(validationResult);
    }

    return _$AuthChallengeRequestFromJson(params);
  }
  final String did;
}
