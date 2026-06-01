import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'response_error_model.g.dart';

enum GroupMemberDeregisterErrorCodes {
  notInGroup('group_member_not_in_group'),
  notFound('group_not_found'),
  deleted('group_deleted');

  const GroupMemberDeregisterErrorCodes(this.value);

  final String value;
}

@JsonSerializable()
class GroupMemberDeregisterErrorResponse {
  GroupMemberDeregisterErrorResponse({
    required this.errorCode,
    required this.errorMessage,
  });

  factory GroupMemberDeregisterErrorResponse.notInGroup() {
    return GroupMemberDeregisterErrorResponse(
      errorCode: GroupMemberDeregisterErrorCodes.notInGroup.value,
      errorMessage: 'Deregister member failed: group member not in group.',
    );
  }

  factory GroupMemberDeregisterErrorResponse.notFound() {
    return GroupMemberDeregisterErrorResponse(
      errorCode: GroupMemberDeregisterErrorCodes.notFound.value,
      errorMessage: 'Deregister member failed: group not found.',
    );
  }

  factory GroupMemberDeregisterErrorResponse.deleted() {
    return GroupMemberDeregisterErrorResponse(
      errorCode: GroupMemberDeregisterErrorCodes.deleted.value,
      errorMessage: 'Deregister member failed: group has been deleted.',
    );
  }

  final String errorCode;
  final String errorMessage;

  @override
  String toString() => jsonEncode(toJson());

  toJson() => _$GroupMemberDeregisterErrorResponseToJson(this);
}
