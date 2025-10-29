import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'response_error_model.g.dart';

enum DeregisterNotificationErrorCodes {
  permissionDenied('permission_denied'),
  notFound('not_found');

  const DeregisterNotificationErrorCodes(this.value);

  final String value;
}

@JsonSerializable()
class DeregisterNotificationErrorResponse {
  DeregisterNotificationErrorResponse({
    required this.errorCode,
    required this.errorMessage,
  });

  factory DeregisterNotificationErrorResponse.permissionDenied() {
    return DeregisterNotificationErrorResponse(
      errorCode: DeregisterNotificationErrorCodes.permissionDenied.value,
      errorMessage:
          'Requester is not allowed to deregister given notification token',
    );
  }

  factory DeregisterNotificationErrorResponse.notFound() {
    return DeregisterNotificationErrorResponse(
      errorCode: DeregisterNotificationErrorCodes.notFound.value,
      errorMessage: 'Notification channel not found',
    );
  }

  final String errorCode;
  final String errorMessage;

  @override
  String toString() => jsonEncode(toJson());

  toJson() => _$DeregisterNotificationErrorResponseToJson(this);
}
