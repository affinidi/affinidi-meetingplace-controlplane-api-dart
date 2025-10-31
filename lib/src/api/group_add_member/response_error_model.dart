import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'response_error_model.g.dart';

enum GroupAddMemberErrorCodes {
  groupDoesNotExist('group_does_not_exist'),
  permissionDenied('group_add_member_permission_denied'),
  groupDeleted('group_deleted');

  const GroupAddMemberErrorCodes(this.value);

  final String value;
}

@JsonSerializable()
class GroupAddMemberErrorResponse {
  GroupAddMemberErrorResponse({
    required this.errorCode,
    required this.errorMessage,
  });

  factory GroupAddMemberErrorResponse.groupDoesNotExist() {
    return GroupAddMemberErrorResponse(
      errorCode: GroupAddMemberErrorCodes.groupDoesNotExist.value,
      errorMessage: 'Group add member exception: Group does not exist',
    );
  }

  factory GroupAddMemberErrorResponse.permissionDenied() {
    return GroupAddMemberErrorResponse(
      errorCode: GroupAddMemberErrorCodes.permissionDenied.value,
      errorMessage:
          '''Group add member exception: The requester does not have permission to add a member to the group.''',
    );
  }

  factory GroupAddMemberErrorResponse.groupDeleted() {
    return GroupAddMemberErrorResponse(
      errorCode: GroupAddMemberErrorCodes.groupDeleted.value,
      errorMessage: 'Group add member exception: Group has been deleted',
    );
  }

  final String errorCode;
  final String errorMessage;

  @override
  String toString() => jsonEncode(toJson());

  toJson() => _$GroupAddMemberErrorResponseToJson(this);
}
