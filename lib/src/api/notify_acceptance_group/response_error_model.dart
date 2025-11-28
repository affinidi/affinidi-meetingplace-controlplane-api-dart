import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../error_helper.dart';

part 'response_error_model.g.dart';

enum NotifyAcceptanceGroupErrorCodes {
  offerNotFound('OFFER_NOT_FOUND'),
  acceptanceNotFound('ACCEPTANCE_NOT_FOUND'),
  notificationError('UPSTREAM_NOTIFICATION_ERROR');

  const NotifyAcceptanceGroupErrorCodes(this.value);

  final String value;
}

@JsonSerializable()
class NotifyAcceptanceGroupErrorResponse {
  NotifyAcceptanceGroupErrorResponse({
    required this.errorCode,
    required this.errorMessage,
  });

  factory NotifyAcceptanceGroupErrorResponse.offerNotFound() {
    return NotifyAcceptanceGroupErrorResponse(
      errorCode: NotifyAcceptanceGroupErrorCodes.offerNotFound.value,
      errorMessage: 'Offer not found, notify acceptance group not possible',
    );
  }

  factory NotifyAcceptanceGroupErrorResponse.acceptanceNotFound() {
    return NotifyAcceptanceGroupErrorResponse(
      errorCode: NotifyAcceptanceGroupErrorCodes.acceptanceNotFound.value,
      errorMessage: 'Acceptance not found, notify acceptance goup not possible',
    );
  }

  factory NotifyAcceptanceGroupErrorResponse.notificationError([
    String? message,
  ]) {
    return NotifyAcceptanceGroupErrorResponse(
      errorCode: NotifyAcceptanceGroupErrorCodes.notificationError.value,
      errorMessage: ErrorHelper.getNotificationErrorMessage(message),
    );
  }

  final String errorCode;
  final String errorMessage;

  @override
  String toString() =>
      jsonEncode(_$NotifyAcceptanceGroupErrorResponseToJson(this));

  toJson() => _$NotifyAcceptanceGroupErrorResponseToJson(this);
}
