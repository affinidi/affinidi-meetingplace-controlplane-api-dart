import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

import '../request_validation_exception.dart';
import 'request_validator.dart';

part 'request_model.g.dart';

@JsonSerializable()
class MatrixChallengeRequest {
  MatrixChallengeRequest({required this.did});

  factory MatrixChallengeRequest.fromRequestParams(String requestParams) {
    final params = jsonDecode(requestParams);

    final validationResult = MatrixChallengeRequestValidator().validate(params);

    if (!validationResult.isValid) {
      throw RequestValidationException.fromValidationResult(validationResult);
    }

    return _$MatrixChallengeRequestFromJson(params);
  }

  final String did;
}
