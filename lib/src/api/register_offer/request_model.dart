import 'dart:convert';
import '../../utils/platform_type.dart';
import 'package:json_annotation/json_annotation.dart';

import '../request_validation_exception.dart';
import 'request_validator.dart';

part 'request_model.g.dart';

@JsonSerializable()
class RegisterOfferRequest {
  RegisterOfferRequest({
    required this.offerName,
    required this.offerDescription,
    required this.didcommMessage,
    required this.contactCard,
    required this.deviceToken,
    required this.platformType,
    required this.mediatorDid,
    required this.mediatorEndpoint,
    required this.mediatorWSSEndpoint,
    required this.contactAttributes,
    this.validUntil,
    this.maximumUsage,
    customPhrase,
  }) : customPhrase = customPhrase == '' ? null : customPhrase;

  factory RegisterOfferRequest.fromRequestParams(String requestParams) {
    final params = jsonDecode(requestParams);

    final validationResult = RegisterOfferRequestValidator().validate(params);

    if (!validationResult.isValid) {
      throw RequestValidationException.fromValidationResult(validationResult);
    }

    return _$RegisterOfferRequestFromJson(params);
  }

  final String offerName;
  final String offerDescription;
  final String didcommMessage;
  final String contactCard;
  final String deviceToken;
  final PlatformType platformType;
  final String mediatorDid;
  final String mediatorEndpoint;
  final String mediatorWSSEndpoint;
  final int contactAttributes;
  final int? maximumUsage;
  final String? validUntil;
  final String? customPhrase;

  toJson() => _$RegisterOfferRequestToJson(this);
}
