import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../request_validation_exception.dart';
import 'request_validator.dart';

part 'request_model.g.dart';

@JsonSerializable()
class GroupSendMessage {
  factory GroupSendMessage.fromRequestParams(String requestParams) {
    final params = jsonDecode(requestParams);

    final validationResult = GroupSendMessageValidator().validate(params);

    if (!validationResult.isValid) {
      throw RequestValidationException.fromValidationResult(validationResult);
    }

    return _$GroupSendMessageFromJson(params);
  }

  GroupSendMessage({
    required this.offerLink,
    required this.groupDid,
    required this.payload,
    required this.ephemeral,
    required this.expiresTime,
    this.notify = false,
    this.incSeqNo = false,
  });
  final String offerLink;
  final String groupDid;
  final String payload;
  final bool? ephemeral;
  final String? expiresTime;

  final bool notify;
  final bool incSeqNo;

  toJson() => _$GroupSendMessageToJson(this);
}
