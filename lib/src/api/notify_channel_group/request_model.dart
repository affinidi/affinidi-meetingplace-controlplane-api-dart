import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

import '../request_validation_exception.dart';
import 'request_validator.dart';

part 'request_model.g.dart';

@JsonSerializable()
class NotifyChannelGroupRequest {
  NotifyChannelGroupRequest({required this.groupId, required this.type});

  factory NotifyChannelGroupRequest.fromRequestParams(String requestParams) {
    final params = jsonDecode(requestParams);

    final validationResult = NotifyChannelGroupRequestValidator().validate(
      params,
    );

    if (!validationResult.isValid) {
      throw RequestValidationException.fromValidationResult(validationResult);
    }

    return _$NotifyChannelGroupRequestFromJson(params);
  }

  final String groupId;
  final String type;

  toJson() => _$NotifyChannelGroupRequestToJson(this);
}
