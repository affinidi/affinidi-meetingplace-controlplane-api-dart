import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'response_error_model.g.dart';

enum GetPendingNotificationsErrorCodes {
  permissionDenied('permission_denied');

  const GetPendingNotificationsErrorCodes(this.value);

  final String value;
}

@JsonSerializable()
class GetPendingNotificationsErrorResponse {
  GetPendingNotificationsErrorResponse({
    required this.errorCode,
    required this.errorMessage,
  });

  factory GetPendingNotificationsErrorResponse.permissionDenied() {
    return GetPendingNotificationsErrorResponse(
      errorCode: GetPendingNotificationsErrorCodes.permissionDenied.value,
      errorMessage:
          'Requester is not allowed to access this device token mapping',
    );
  }

  final String errorCode;
  final String errorMessage;

  @override
  String toString() => jsonEncode(toJson());

  toJson() => _$GetPendingNotificationsErrorResponseToJson(this);
}
