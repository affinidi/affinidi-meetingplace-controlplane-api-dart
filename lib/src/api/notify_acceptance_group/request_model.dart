import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

import '../request_validation_exception.dart';
import 'request_validator.dart';

part 'request_model.g.dart';

@JsonSerializable()
class NotifyAcceptanceGroupRequest {
  NotifyAcceptanceGroupRequest({
    required this.mnemonic,
    required this.offerLink,
    required this.did,
    required this.senderInfo,
  });

  factory NotifyAcceptanceGroupRequest.fromRequestParams(String requestParams) {
    final params = jsonDecode(requestParams);

    final validationResult =
        NotifyAcceptanceGroupRequestValidator().validate(params);

    if (!validationResult.isValid) {
      throw RequestValidationException.fromValidationResult(validationResult);
    }

    return _$NotifyAcceptanceGroupRequestFromJson(params);
  }

  final String mnemonic;
  final String offerLink;
  final String did;
  final String senderInfo;

  toJson() => _$NotifyAcceptanceGroupRequestToJson(this);
}
