import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'response_error_model.g.dart';

enum GroupNotifyChannelErrorCodes {
  notInGroup('group_member_not_in_group'),
  notFound('group_not_found'),
  deleted('group_deleted');

  const GroupNotifyChannelErrorCodes(this.value);

  final String value;
}

@JsonSerializable()
class GroupNotifyChannelErrorResponse {
  GroupNotifyChannelErrorResponse({
    required this.errorCode,
    required this.errorMessage,
  });

  factory GroupNotifyChannelErrorResponse.notInGroup() {
    return GroupNotifyChannelErrorResponse(
      errorCode: GroupNotifyChannelErrorCodes.notInGroup.value,
      errorMessage: 'Notify channel failed: group member not in group.',
    );
  }

  factory GroupNotifyChannelErrorResponse.notFound() {
    return GroupNotifyChannelErrorResponse(
      errorCode: GroupNotifyChannelErrorCodes.notFound.value,
      errorMessage: 'Notify channel failed: group not found.',
    );
  }

  factory GroupNotifyChannelErrorResponse.deleted() {
    return GroupNotifyChannelErrorResponse(
      errorCode: GroupNotifyChannelErrorCodes.deleted.value,
      errorMessage: 'Notify channel failed: group has been deleted.',
    );
  }

  final String errorCode;
  final String errorMessage;

  @override
  String toString() => jsonEncode(toJson());

  toJson() => _$GroupNotifyChannelErrorResponseToJson(this);
}
