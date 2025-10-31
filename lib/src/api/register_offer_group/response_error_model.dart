import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'response_error_model.g.dart';

enum RegisterOfferGroupErrorCodes {
  groupCountLimitExceeded('group_count_limit_exceeded'),
  invalidInput('INVALID_INPUT');

  const RegisterOfferGroupErrorCodes(this.value);

  final String value;
}

@JsonSerializable()
class RegisterOfferGroupErrorResponse {
  RegisterOfferGroupErrorResponse({
    required this.errorCode,
    required this.errorMessage,
  });

  factory RegisterOfferGroupErrorResponse.groupCountLimitExceeded() {
    return RegisterOfferGroupErrorResponse(
      errorCode: RegisterOfferGroupErrorCodes.groupCountLimitExceeded.value,
      errorMessage:
          'Register offer group exception: group count limit exceeded',
    );
  }

  factory RegisterOfferGroupErrorResponse.invalidInput(String message) {
    return RegisterOfferGroupErrorResponse(
      errorCode: RegisterOfferGroupErrorCodes.invalidInput.value,
      errorMessage: message,
    );
  }

  final String errorCode;
  final String errorMessage;

  @override
  String toString() => jsonEncode(toJson());

  toJson() => _$RegisterOfferGroupErrorResponseToJson(this);
}
