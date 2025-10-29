import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'response_error_model.g.dart';

enum GroupSendMessageErrorCodes {
  generic('generic');

  const GroupSendMessageErrorCodes(this.value);

  final String value;
}

@JsonSerializable()
class GroupSendMemberErrorResponse {
  GroupSendMemberErrorResponse({
    required this.errorCode,
    required this.errorMessage,
  });

  factory GroupSendMemberErrorResponse.groupDoesNotExist() {
    return GroupSendMemberErrorResponse(
      errorCode: GroupSendMessageErrorCodes.generic.value,
      errorMessage: 'Error sending group message',
    );
  }
  final String errorCode;
  final String errorMessage;

  @override
  String toString() => jsonEncode(toJson());

  toJson() => _$GroupSendMemberErrorResponseToJson(this);
}
