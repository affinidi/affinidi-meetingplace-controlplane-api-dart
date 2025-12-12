import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'response_error_model.g.dart';

enum QueryOfferErrorCodes {
  @JsonValue('QUERY_LIMIT_EXCEEDED')
  queryLimitExceeded('QUERY_LIMIT_EXCEEDED'),

  @JsonValue('NOT_FOUND')
  notFound('NOT_FOUND'),

  @JsonValue('OFFER_EXPIRED')
  offerExpired('OFFER_EXPIRED');

  const QueryOfferErrorCodes(this.value);

  final String value;
}

@JsonSerializable()
class QueryOfferErrorResponse {
  QueryOfferErrorResponse({
    required this.errorCode,
    required this.errorMessage,
  });

  factory QueryOfferErrorResponse.notFound() {
    return QueryOfferErrorResponse(
      errorCode: QueryOfferErrorCodes.notFound.value,
      errorMessage: 'Offer not found',
    );
  }

  factory QueryOfferErrorResponse.limitExceeded() {
    return QueryOfferErrorResponse(
      errorCode: QueryOfferErrorCodes.queryLimitExceeded.value,
      errorMessage: 'Offer query limit exceeded',
    );
  }

  factory QueryOfferErrorResponse.offerExpired() {
    return QueryOfferErrorResponse(
      errorCode: QueryOfferErrorCodes.offerExpired.value,
      errorMessage: 'The offer has expired',
    );
  }

  final String errorCode;
  final String errorMessage;

  @override
  String toString() =>
      JsonEncoder().convert(_$QueryOfferErrorResponseToJson(this));

  toJson() => _$QueryOfferErrorResponseToJson(this);
}
