import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../request_validation_exception.dart';
import 'request_validator.dart';

part 'request_model.g.dart';

@JsonSerializable()
class GroupMemberDeregisterRequest {
  factory GroupMemberDeregisterRequest.fromRequestParams(String requestParams) {
    final params = jsonDecode(requestParams);

    final validationResult =
        GroupMemberDeregisterRequestValidator().validate(params);

    if (!validationResult.isValid) {
      throw RequestValidationException.fromValidationResult(validationResult);
    }

    return _$GroupMemberDeregisterRequestFromJson(params);
  }

  GroupMemberDeregisterRequest({
    required this.groupId,
    required this.memberDid,
    required this.messageToRelay,
  });

  final String groupId;
  final String memberDid;
  final String messageToRelay;

  toJson() => _$GroupMemberDeregisterRequestToJson(this);
}
