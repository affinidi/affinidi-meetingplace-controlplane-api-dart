import 'dart:convert';
import '../../utils/platform_type.dart';
import 'package:json_annotation/json_annotation.dart';

import '../request_validation_exception.dart';
import 'request_validator.dart';

part 'request_model.g.dart';

@JsonSerializable()
class DeletePendingNotificationsRequest {
  DeletePendingNotificationsRequest({
    required this.deviceToken,
    required this.platformType,
    required this.notificationIds,
  });

  factory DeletePendingNotificationsRequest.fromRequestParams(
    String requestParams,
  ) {
    final params = jsonDecode(requestParams);

    final validationResult =
        DeletePendingNotificationsRequestValidator().validate(params);

    if (!validationResult.isValid) {
      throw RequestValidationException.fromValidationResult(validationResult);
    }

    return _$DeletePendingNotificationsRequestFromJson(params);
  }
  final String deviceToken;
  final PlatformType platformType;
  final List<String> notificationIds;

  toJson() => _$DeletePendingNotificationsRequestToJson(this);
}
