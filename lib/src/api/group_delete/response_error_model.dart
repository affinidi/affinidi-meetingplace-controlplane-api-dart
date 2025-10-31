import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'response_error_model.g.dart';

enum GroupDeleteErrorCodes {
  groupDoesNotExist('group_does_not_exist'),
  groupPermissionDenied('group_permission_denied'),
  groupDeleted('group_deleted');

  const GroupDeleteErrorCodes(this.value);

  final String value;
}

@JsonSerializable()
class GroupDeleteErrorResponse {
  GroupDeleteErrorResponse({
    required this.errorCode,
    required this.errorMessage,
  });

  factory GroupDeleteErrorResponse.groupDoesNotExist() {
    return GroupDeleteErrorResponse(
      errorCode: GroupDeleteErrorCodes.groupDoesNotExist.value,
      errorMessage: 'Group delete exception: Group does not exist',
    );
  }

  factory GroupDeleteErrorResponse.groupPermissionDenied() {
    return GroupDeleteErrorResponse(
      errorCode: GroupDeleteErrorCodes.groupPermissionDenied.value,
      errorMessage:
          'Group delete exception: only group owners are allowed to delete group',
    );
  }

  factory GroupDeleteErrorResponse.groupDeleted() {
    return GroupDeleteErrorResponse(
      errorCode: GroupDeleteErrorCodes.groupDeleted.value,
      errorMessage: 'Group delete exception: Group has been deleted',
    );
  }

  final String errorCode;
  final String errorMessage;

  @override
  String toString() => jsonEncode(toJson());

  toJson() => _$GroupDeleteErrorResponseToJson(this);
}
