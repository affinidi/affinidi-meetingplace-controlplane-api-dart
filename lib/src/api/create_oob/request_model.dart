import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

import '../request_validation_exception.dart';
import 'request_validator.dart';

part 'request_model.g.dart';

@JsonSerializable()
class CreateOobRequest {
  CreateOobRequest({
    required this.mediatorDid,
    required this.mediatorEndpoint,
    required this.mediatorWSSEndpoint,
    required this.didcommMessage,
  });

  factory CreateOobRequest.fromRequestParams(String requestParams) {
    final params = jsonDecode(requestParams);

    final validationResult = CreateOobRequestValidator().validate(params);

    if (!validationResult.isValid) {
      throw RequestValidationException.fromValidationResult(validationResult);
    }
    return _$CreateOobRequestFromJson(params);
  }

  final String mediatorDid;
  final String mediatorEndpoint;
  final String mediatorWSSEndpoint;
  final String didcommMessage;

  toJson() => _$CreateOobRequestToJson(this);
}
