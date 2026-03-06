import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'response_error_model.g.dart';

enum AcceptOfferGroupErrorCodes {
  notFound('NOT_FOUND'),
  invalid('INVALID_OFFER'),
  claimLimitExceeded('CLAIM_LIMIT_EXCEEDED');

  const AcceptOfferGroupErrorCodes(this.value);

  final String value;
}

@JsonSerializable()
class AcceptOfferGroupErrorResponse {
  AcceptOfferGroupErrorResponse({
    required this.errorCode,
    required this.errorMessage,
  });

  factory AcceptOfferGroupErrorResponse.offerNotFound() {
    return AcceptOfferGroupErrorResponse(
      errorCode: AcceptOfferGroupErrorCodes.notFound.value,
      errorMessage: 'Offer not found. Offer acceptance not possible',
    );
  }

  factory AcceptOfferGroupErrorResponse.offerInvalid() {
    return AcceptOfferGroupErrorResponse(
      errorCode: AcceptOfferGroupErrorCodes.invalid.value,
      errorMessage: 'Offer is no longer valid',
    );
  }

  factory AcceptOfferGroupErrorResponse.claimLimitExceeded() {
    return AcceptOfferGroupErrorResponse(
      errorCode: AcceptOfferGroupErrorCodes.claimLimitExceeded.value,
      errorMessage: 'Offer claim limit exceeded',
    );
  }

  final String errorCode;
  final String errorMessage;

  @override
  String toString() =>
      JsonEncoder().convert(_$AcceptOfferGroupErrorResponseToJson(this));

  toJson() => _$AcceptOfferGroupErrorResponseToJson(this);
}
