import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'response_error_model.g.dart';

enum NotifyChannelGroupErrorCodes {
  groupNotFound('group_not_found'),
  groupDeleted('group_deleted'),
  notInGroup('group_member_not_in_group');

  const NotifyChannelGroupErrorCodes(this.value);

  final String value;
}

@JsonSerializable()
class NotifyChannelGroupErrorResponse {
  NotifyChannelGroupErrorResponse({
    required this.errorCode,
    required this.errorMessage,
  });

  factory NotifyChannelGroupErrorResponse.groupNotFound() {
    return NotifyChannelGroupErrorResponse(
      errorCode: NotifyChannelGroupErrorCodes.groupNotFound.value,
      errorMessage: 'Notify channel group exception: group not found',
    );
  }

  factory NotifyChannelGroupErrorResponse.groupDeleted() {
    return NotifyChannelGroupErrorResponse(
      errorCode: NotifyChannelGroupErrorCodes.groupDeleted.value,
      errorMessage: 'Notify channel group exception: group has been deleted',
    );
  }

  factory NotifyChannelGroupErrorResponse.notInGroup() {
    return NotifyChannelGroupErrorResponse(
      errorCode: NotifyChannelGroupErrorCodes.notInGroup.value,
      errorMessage:
          'Notify channel group exception: caller is not a member of the group',
    );
  }

  final String errorCode;
  final String errorMessage;

  @override
  String toString() => JsonEncoder().convert(toJson());

  toJson() => _$NotifyChannelGroupErrorResponseToJson(this);
}
