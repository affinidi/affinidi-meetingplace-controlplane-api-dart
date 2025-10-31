import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

import '../request_validation_exception.dart';
import 'request_validator.dart';

part 'request_model.g.dart';

@JsonSerializable()
class DeregisterNotificationRequest {
  DeregisterNotificationRequest({
    required this.notificationToken,
  });

  factory DeregisterNotificationRequest.fromRequestParams(
    String requestParams,
  ) {
    final params = jsonDecode(requestParams);

    final validationResult =
        DeregisterNotificationRequestValidator().validate(params);

    if (!validationResult.isValid) {
      throw RequestValidationException.fromValidationResult(validationResult);
    }

    return _$DeregisterNotificationRequestFromJson(params);
  }
  final String notificationToken;

  toJson() => _$DeregisterNotificationRequestToJson(this);
}
