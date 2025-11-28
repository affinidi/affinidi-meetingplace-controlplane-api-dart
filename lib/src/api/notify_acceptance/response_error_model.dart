import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../error_helper.dart';

part 'response_error_model.g.dart';

enum NotifyAcceptanceErrorCodes {
  offerNotFound('OFFER_NOT_FOUND'),
  acceptanceNotFound('ACCEPTANCE_NOT_FOUND'),
  notificationError('NOTIFICATION_ERROR');

  const NotifyAcceptanceErrorCodes(this.value);

  final String value;
}

@JsonSerializable()
class NotifyAcceptanceErrorResponse {
  NotifyAcceptanceErrorResponse({
    required this.errorCode,
    required this.errorMessage,
  });

  factory NotifyAcceptanceErrorResponse.offerNotFound() {
    return NotifyAcceptanceErrorResponse(
      errorCode: NotifyAcceptanceErrorCodes.offerNotFound.value,
      errorMessage: 'Offer not found, notify acceptance not possible',
    );
  }

  factory NotifyAcceptanceErrorResponse.acceptanceNotFound() {
    return NotifyAcceptanceErrorResponse(
      errorCode: NotifyAcceptanceErrorCodes.acceptanceNotFound.value,
      errorMessage: 'Acceptance not found, notify acceptance not possible',
    );
  }

  factory NotifyAcceptanceErrorResponse.notificationError([String? message]) {
    return NotifyAcceptanceErrorResponse(
      errorCode: NotifyAcceptanceErrorCodes.notificationError.value,
      errorMessage: ErrorHelper.getMotificationErrorMessage(message),
    );
  }

  final String errorCode;
  final String errorMessage;

  @override
  String toString() =>
      JsonEncoder().convert(_$NotifyAcceptanceErrorResponseToJson(this));

  toJson() => _$NotifyAcceptanceErrorResponseToJson(this);
}
