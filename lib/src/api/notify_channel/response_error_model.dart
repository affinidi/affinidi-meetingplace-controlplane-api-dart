import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../error_helper.dart';

part 'response_error_model.g.dart';

enum NotifyAcceptanceErrorCodes {
  @JsonValue('NOTIFICATION_CHANNEL_NOT_FOUND')
  channelNotFound('NOTIFICATION_CHANNEL_NOT_FOUND'),
  notificationError('NOTIFICATION_ERROR');

  const NotifyAcceptanceErrorCodes(this.value);

  final String value;
}

@JsonSerializable()
class NotifyChannelErrorResponse {
  NotifyChannelErrorResponse({
    required this.errorCode,
    required this.errorMessage,
  });

  factory NotifyChannelErrorResponse.notificationChannelNotFound() {
    return NotifyChannelErrorResponse(
      errorCode: NotifyAcceptanceErrorCodes.channelNotFound.value,
      errorMessage:
          'Notification channel not found, notify channel not possible',
    );
  }

  factory NotifyChannelErrorResponse.notificationError([String? message]) {
    return NotifyChannelErrorResponse(
      errorCode: NotifyAcceptanceErrorCodes.notificationError.value,
      errorMessage: ErrorHelper.getMotificationErrorMessage(message),
    );
  }

  final String errorCode;
  final String errorMessage;

  @override
  String toString() =>
      JsonEncoder().convert(_$NotifyChannelErrorResponseToJson(this));

  toJson() => _$NotifyChannelErrorResponseToJson(this);
}
