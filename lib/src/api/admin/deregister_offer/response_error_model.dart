import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'response_error_model.g.dart';

enum AdminDeregisterOfferErrorCodes {
  permissionDenied('permission_denied'),
  notFound('not_found'),
  offerLinkMismatch('offer_link_mismatch');

  const AdminDeregisterOfferErrorCodes(this.value);

  final String value;
}

@JsonSerializable()
class AdminDeregisterOfferErrorResponse {
  AdminDeregisterOfferErrorResponse({
    required this.errorCode,
    required this.errorMessage,
  });

  factory AdminDeregisterOfferErrorResponse.permissionDenied() {
    return AdminDeregisterOfferErrorResponse(
      errorCode: AdminDeregisterOfferErrorCodes.permissionDenied.value,
      errorMessage:
          '''Deregister offer exception: only offer owners are allowed to deregister offers''',
    );
  }

  factory AdminDeregisterOfferErrorResponse.notFound() {
    return AdminDeregisterOfferErrorResponse(
      errorCode: AdminDeregisterOfferErrorCodes.notFound.value,
      errorMessage:
          '''Deregister offer exception: offer not found or it was already deleted''',
    );
  }

  final String errorCode;
  final String errorMessage;

  @override
  String toString() => jsonEncode(toJson());

  toJson() => _$AdminDeregisterOfferErrorResponseToJson(this);
}
