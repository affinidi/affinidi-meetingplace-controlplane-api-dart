import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

import '../request_validation_exception.dart';
import 'request_validator.dart';

part 'request_model.g.dart';

@JsonSerializable()
class GetOobRequest {
  GetOobRequest({required this.oobId});

  factory GetOobRequest.fromRequestParams(String requestParams) {
    final params = jsonDecode(requestParams);

    final validationResult = GetOobRequestValidator().validate(params);

    if (!validationResult.isValid) {
      throw RequestValidationException.fromValidationResult(validationResult);
    }
    return _$GetOobRequestFromJson(params);
  }
  final String oobId;
}
