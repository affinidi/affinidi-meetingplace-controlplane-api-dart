import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'response_error_model.g.dart';

enum RegisterOfferErrorCodes {
  invalidInput('INVALID_INPUT');

  const RegisterOfferErrorCodes(this.value);

  final String value;
}

@JsonSerializable()
class RegisterOfferErrorResponse {
  RegisterOfferErrorResponse({
    required this.errorCode,
    required this.errorMessage,
  });

  factory RegisterOfferErrorResponse.invalidInput(String message) {
    return RegisterOfferErrorResponse(
      errorCode: RegisterOfferErrorCodes.invalidInput.value,
      errorMessage: message,
    );
  }

  final String errorCode;
  final String errorMessage;

  @override
  String toString() => jsonEncode(toJson());

  toJson() => _$RegisterOfferErrorResponseToJson(this);
}
