import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../request_validation_exception.dart';
import 'request_validator.dart';

part 'request_model.g.dart';

@JsonSerializable()
class GroupNotifyChannel {
  factory GroupNotifyChannel.fromRequestParams(String requestParams) {
    final params = jsonDecode(requestParams);

    final validationResult = GroupNotifyChannelValidator().validate(params);

    if (!validationResult.isValid) {
      throw RequestValidationException.fromValidationResult(validationResult);
    }

    return _$GroupNotifyChannelFromJson(params);
  }

  GroupNotifyChannel({
    required this.offerLink,
    required this.groupDid,
    required this.type,
    this.memberDid,
  });
  final String offerLink;
  final String groupDid;
  final String type;

  /// When set, notify only this single group member instead of all members.
  final String? memberDid;

  toJson() => _$GroupNotifyChannelToJson(this);
}
