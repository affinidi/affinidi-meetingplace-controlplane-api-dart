import 'dart:convert';
import '../../utils/platform_type.dart';
import 'package:json_annotation/json_annotation.dart';

import '../request_validation_exception.dart';
import 'request_validator.dart';

part 'request_model.g.dart';

@JsonSerializable()
class RegisterNotificationRequest {
  RegisterNotificationRequest({
    required this.myDid,
    required this.theirDid,
    required this.deviceToken,
    required this.platformType,
  });

  factory RegisterNotificationRequest.fromRequestParams(String requestParams) {
    final params = jsonDecode(requestParams);

    final validationResult = RegisterNotificationRequestValidator().validate(
      params,
    );

    if (!validationResult.isValid) {
      throw RequestValidationException.fromValidationResult(validationResult);
    }

    return _$RegisterNotificationRequestFromJson(params);
  }
  final String myDid;
  final String theirDid;
  final String deviceToken;
  final PlatformType platformType;

  toJson() => _$RegisterNotificationRequestToJson(this);
}
