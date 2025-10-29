import 'dart:convert';
import '../../utils/platform_type.dart';
import 'package:json_annotation/json_annotation.dart';

import '../request_validation_exception.dart';
import 'request_validator.dart';

part 'request_model.g.dart';

@JsonSerializable()
class FinaliseAcceptanceRequest {
  FinaliseAcceptanceRequest({
    required this.did,
    required this.theirDid,
    required this.mnemonic,
    required this.offerLink,
    this.deviceToken,
    this.platformType,
  });

  factory FinaliseAcceptanceRequest.fromRequestParams(String requestParams) {
    final params = jsonDecode(requestParams);

    final validationResult =
        FinaliseAcceptanceRequestValidator().validate(params);

    if (!validationResult.isValid) {
      throw RequestValidationException.fromValidationResult(validationResult);
    }

    return _$FinaliseAcceptanceRequestFromJson(params);
  }
  final String did;
  final String theirDid;
  final String mnemonic;
  final String offerLink;
  final String? deviceToken;
  final PlatformType? platformType;

  toJson() => _$FinaliseAcceptanceRequestToJson(this);
}
