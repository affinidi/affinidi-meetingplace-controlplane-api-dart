import 'dart:convert';

import '../../utils/platform_type.dart';
import 'package:json_annotation/json_annotation.dart';

import '../request_validation_exception.dart';
import 'request_validator.dart';

part 'request_model.g.dart';

@JsonSerializable()
class AcceptOfferRequest {
  AcceptOfferRequest({
    required this.did,
    required this.mnemonic,
    required this.deviceToken,
    required this.platformType,
    required this.vcard,
  });

  factory AcceptOfferRequest.fromRequestParams(String requestParams) {
    final params = jsonDecode(requestParams);

    final validationResult = AcceptOfferRequestValidator().validate(params);

    if (!validationResult.isValid) {
      throw RequestValidationException.fromValidationResult(validationResult);
    }

    return _$AcceptOfferRequestFromJson(params);
  }

  final String did;
  final String mnemonic;
  final String deviceToken;
  final PlatformType platformType;
  final String vcard;

  toJson() => _$AcceptOfferRequestToJson(this);
}
