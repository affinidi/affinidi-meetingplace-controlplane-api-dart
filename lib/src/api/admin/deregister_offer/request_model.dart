import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

import '../../request_validation_exception.dart';
import 'request_validator.dart';

part 'request_model.g.dart';

@JsonSerializable()
class AdminDeregisterOfferRequest {
  AdminDeregisterOfferRequest({required this.mnemonic});

  factory AdminDeregisterOfferRequest.fromRequestParams(String requestParams) {
    final params = jsonDecode(requestParams);

    final validationResult = AdminDeregisterOfferRequestValidator().validate(
      params,
    );

    if (!validationResult.isValid) {
      throw RequestValidationException.fromValidationResult(validationResult);
    }

    return _$AdminDeregisterOfferRequestFromJson(params);
  }
  final String mnemonic;

  toJson() => _$AdminDeregisterOfferRequestToJson(this);
}
