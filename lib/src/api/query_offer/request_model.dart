import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

import '../request_validation_exception.dart';
import 'request_validator.dart';

part 'request_model.g.dart';

@JsonSerializable()
class QueryOfferRequest {
  QueryOfferRequest({required this.mnemonic});

  factory QueryOfferRequest.fromRequestParams(String requestParams) {
    final params = jsonDecode(requestParams);

    final validationResult = QueryOfferRequestValidator().validate(params);

    if (!validationResult.isValid) {
      throw RequestValidationException.fromValidationResult(validationResult);
    }

    return _$QueryOfferRequestFromJson(params);
  }
  final String mnemonic;

  toJson() => _$QueryOfferRequestToJson(this);
}
