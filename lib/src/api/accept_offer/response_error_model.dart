import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'response_error_model.g.dart';

enum AcceptOfferErrorCodes {
  notFound('NOT_FOUND'),
  invalid('INVALID_OFFER');

  const AcceptOfferErrorCodes(this.value);

  final String value;
}

@JsonSerializable()
class AcceptOfferErrorResponse {
  AcceptOfferErrorResponse({
    required this.errorCode,
    required this.errorMessage,
  });

  factory AcceptOfferErrorResponse.offerNotFound() {
    return AcceptOfferErrorResponse(
      errorCode: AcceptOfferErrorCodes.notFound.value,
      errorMessage: 'Offer not found. Offer acceptance not possible',
    );
  }

  factory AcceptOfferErrorResponse.offerInvalid() {
    return AcceptOfferErrorResponse(
      errorCode: AcceptOfferErrorCodes.invalid.value,
      errorMessage: 'Offer is no longer valid',
    );
  }
  final String errorCode;
  final String errorMessage;

  @override
  String toString() =>
      JsonEncoder().convert(_$AcceptOfferErrorResponseToJson(this));

  toJson() => _$AcceptOfferErrorResponseToJson(this);
}
