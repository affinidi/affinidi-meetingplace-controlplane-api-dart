import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

import '../request_validation_exception.dart';
import 'request_validator.dart';

part 'request_model.g.dart';

@JsonSerializable()
class NotifyOutreachRequest {
  NotifyOutreachRequest({required this.mnemonic, required this.senderInfo});

  factory NotifyOutreachRequest.fromRequestParams(String requestParams) {
    final params = jsonDecode(requestParams);

    final validationResult = NotifyOutreachRequestValidator().validate(params);

    if (!validationResult.isValid) {
      throw RequestValidationException.fromValidationResult(validationResult);
    }

    return _$NotifyOutreachRequestFromJson(params);
  }

  final String mnemonic;
  final String senderInfo;

  toJson() => _$NotifyOutreachRequestToJson(this);
}
