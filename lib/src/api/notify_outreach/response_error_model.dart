import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'response_error_model.g.dart';

enum NotifyOutreachErrorCodes {
  offerNotFound('notify_outreach_offer_not_found');

  const NotifyOutreachErrorCodes(this.value);

  final String value;
}

@JsonSerializable()
class NotifyOutreachErrorResponse {
  NotifyOutreachErrorResponse({
    required this.errorCode,
    required this.errorMessage,
  });

  factory NotifyOutreachErrorResponse.offerNotFound() {
    return NotifyOutreachErrorResponse(
      errorCode: NotifyOutreachErrorCodes.offerNotFound.value,
      errorMessage: 'Notify outreach exception: offer not found',
    );
  }

  final String errorCode;
  final String errorMessage;

  @override
  String toString() =>
      JsonEncoder().convert(_$NotifyOutreachErrorResponseToJson(this));

  toJson() => _$NotifyOutreachErrorResponseToJson(this);
}
