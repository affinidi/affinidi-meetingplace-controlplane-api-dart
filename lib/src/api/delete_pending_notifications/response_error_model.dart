import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'response_error_model.g.dart';

enum DeletePendingNotificationsErrorCodes {
  permissionDenied('permission_denied');

  const DeletePendingNotificationsErrorCodes(this.value);

  final String value;
}

@JsonSerializable()
class DeletePendingNotificationsErrorResponse {
  DeletePendingNotificationsErrorResponse({
    required this.errorCode,
    required this.errorMessage,
  });

  factory DeletePendingNotificationsErrorResponse.permissionDenied() {
    return DeletePendingNotificationsErrorResponse(
      errorCode: DeletePendingNotificationsErrorCodes.permissionDenied.value,
      errorMessage:
          'Requester is not allowed to access this device token mapping',
    );
  }

  final String errorCode;
  final String errorMessage;

  @override
  String toString() => jsonEncode(toJson());

  toJson() => _$DeletePendingNotificationsErrorResponseToJson(this);
}
