import 'dart:convert';
import '../../utils/platform_type.dart';
import 'package:json_annotation/json_annotation.dart';

import '../request_validation_exception.dart';
import 'request_validator.dart';

part 'request_model.g.dart';

@JsonSerializable()
class GetPendingNotificationsRequest {
  GetPendingNotificationsRequest({
    required this.platformType,
    required this.deviceToken,
  });

  factory GetPendingNotificationsRequest.fromRequestParams(
    String requestParams,
  ) {
    final params = jsonDecode(requestParams);

    final validationResult = GetPendingNotificationsRequestValidator().validate(
      params,
    );

    if (!validationResult.isValid) {
      throw RequestValidationException.fromValidationResult(validationResult);
    }

    return _$GetPendingNotificationsRequestFromJson(params);
  }
  final PlatformType platformType;
  final String deviceToken;

  toJson() => _$GetPendingNotificationsRequestToJson(this);
}
