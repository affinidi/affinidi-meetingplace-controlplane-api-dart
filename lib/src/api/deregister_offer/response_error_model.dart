import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'response_error_model.g.dart';

enum DeregisterOfferErrorCodes {
  permissionDenied('permission_denied'),
  notFound('not_found'),
  offerLinkMismatch('offer_link_mismatch');

  const DeregisterOfferErrorCodes(this.value);

  final String value;
}

@JsonSerializable()
class DeregisterOfferErrorResponse {
  DeregisterOfferErrorResponse({
    required this.errorCode,
    required this.errorMessage,
  });

  factory DeregisterOfferErrorResponse.permissionDenied() {
    return DeregisterOfferErrorResponse(
      errorCode: DeregisterOfferErrorCodes.permissionDenied.value,
      errorMessage:
          '''Deregister offer exception: only offer owners are allowed to deregister offers''',
    );
  }

  factory DeregisterOfferErrorResponse.notFound() {
    return DeregisterOfferErrorResponse(
      errorCode: DeregisterOfferErrorCodes.notFound.value,
      errorMessage:
          '''Deregister offer exception: offer not found or it was already deleted''',
    );
  }

  factory DeregisterOfferErrorResponse.offerLinkMismatch() {
    return DeregisterOfferErrorResponse(
      errorCode: DeregisterOfferErrorCodes.offerLinkMismatch.value,
      errorMessage: 'Deregister offer exception: offer link does not match',
    );
  }

  final String errorCode;
  final String errorMessage;

  @override
  String toString() => jsonEncode(toJson());

  toJson() => _$DeregisterOfferErrorResponseToJson(this);
}
