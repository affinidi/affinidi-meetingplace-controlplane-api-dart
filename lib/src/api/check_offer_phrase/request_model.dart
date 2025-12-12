import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

import '../request_validation_exception.dart';
import 'request_validator.dart';

part 'request_model.g.dart';

@JsonSerializable()
class CheckOfferPhraseRequest {
  CheckOfferPhraseRequest({required this.offerPhrase});

  factory CheckOfferPhraseRequest.fromRequestParams(String requestParams) {
    final params = jsonDecode(requestParams);

    final validationResult = CheckOfferPhraseRequestValidator().validate(
      params,
    );

    if (!validationResult.isValid) {
      throw RequestValidationException.fromValidationResult(validationResult);
    }

    return _$CheckOfferPhraseRequestFromJson(params);
  }

  final String offerPhrase;

  toJson() => _$CheckOfferPhraseRequestToJson(this);
}
