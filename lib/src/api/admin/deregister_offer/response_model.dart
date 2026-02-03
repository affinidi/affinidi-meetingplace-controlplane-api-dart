import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'response_model.g.dart';

enum ResponseStatus {
  @JsonValue('success')
  success('success'),

  @JsonValue('error')
  error('error');

  const ResponseStatus(this.value);

  final String value;
}

@JsonSerializable()
class AdminDeregisterOfferResponse {
  AdminDeregisterOfferResponse({required this.status, required this.message});

  factory AdminDeregisterOfferResponse.success() {
    return AdminDeregisterOfferResponse(
      status: ResponseStatus.success.value,
      message: 'Offer deleted successfully',
    );
  }

  factory AdminDeregisterOfferResponse.error() {
    return AdminDeregisterOfferResponse(
      status: ResponseStatus.error.value,
      message: 'Offer not deleted',
    );
  }

  final String status;
  final String message;

  @override
  String toString() =>
      JsonEncoder().convert(_$AdminDeregisterOfferResponseToJson(this));
}
