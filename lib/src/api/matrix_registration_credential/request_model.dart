import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../request_validation_exception.dart';
import 'request_validator.dart';

part 'request_model.g.dart';

@JsonSerializable()
class MatrixRegistrationCredentialRequest {
  MatrixRegistrationCredentialRequest({
    required this.homeserver,
  });

  factory MatrixRegistrationCredentialRequest.fromRequestParams(
    String requestParams,
  ) {
    final params = jsonDecode(requestParams);

    final validationResult = MatrixRegistrationCredentialRequestValidator()
        .validate(params);

    if (!validationResult.isValid) {
      throw RequestValidationException.fromValidationResult(validationResult);
    }

    return _$MatrixRegistrationCredentialRequestFromJson(params);
  }

  final String homeserver;
}
