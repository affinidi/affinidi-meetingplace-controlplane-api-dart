import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

import '../request_validation_exception.dart';
import 'request_validator.dart';

part 'request_model.g.dart';

@JsonSerializable()
class UpdateOffersScoreRequest {
  UpdateOffersScoreRequest({required this.score, required this.offerLinks});

  factory UpdateOffersScoreRequest.fromRequestParams(String requestParams) {
    final params = jsonDecode(requestParams);

    final validationResult = UpdateOffersScoreRequestValidator().validate(
      params,
    );

    if (!validationResult.isValid) {
      throw RequestValidationException.fromValidationResult(validationResult);
    }

    return _$UpdateOffersScoreRequestFromJson(params);
  }

  Map<String, dynamic> toJson() => _$UpdateOffersScoreRequestToJson(this);

  final int score;
  final List<String> offerLinks;
}
