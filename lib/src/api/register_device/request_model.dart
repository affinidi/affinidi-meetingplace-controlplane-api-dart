import 'dart:convert';
import '../../utils/platform_type.dart';
import 'package:json_annotation/json_annotation.dart';

import '../request_validation_exception.dart';
import 'request_validator.dart';

part 'request_model.g.dart';

@JsonSerializable()
class RegisterDeviceRequest {
  RegisterDeviceRequest({
    required this.deviceToken,
    required this.platformType,
  });

  factory RegisterDeviceRequest.fromRequestParams(String requestParams) {
    final params = jsonDecode(requestParams);

    final validationResult = RegisterDeviceRequestValidator().validate(params);

    if (!validationResult.isValid) {
      throw RequestValidationException.fromValidationResult(validationResult);
    }

    return _$RegisterDeviceRequestFromJson(params);
  }

  final String deviceToken;

  final PlatformType platformType;

  toJson() => _$RegisterDeviceRequestToJson(this);
}
