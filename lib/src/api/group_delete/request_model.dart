import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../request_validation_exception.dart';
import 'request_validator.dart';

part 'request_model.g.dart';

@JsonSerializable()
class GroupDeleteRequest {
  factory GroupDeleteRequest.fromRequestParams(String requestParams) {
    final params = jsonDecode(requestParams);

    final validationResult = GroupDeleteRequestValidator().validate(params);

    if (!validationResult.isValid) {
      throw RequestValidationException.fromValidationResult(validationResult);
    }

    return _$GroupDeleteRequestFromJson(params);
  }

  GroupDeleteRequest({required this.groupId, required this.messageToRelay});

  final String groupId;
  final String messageToRelay;

  toJson() => _$GroupDeleteRequestToJson(this);
}
