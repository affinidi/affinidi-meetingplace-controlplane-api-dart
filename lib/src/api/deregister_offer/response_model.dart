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
class DeregisterOfferResponse {
  DeregisterOfferResponse({
    required this.status,
    required this.message,
  });

  factory DeregisterOfferResponse.success() {
    return DeregisterOfferResponse(
      status: ResponseStatus.success.value,
      message: 'Offer deleted successfully',
    );
  }

  factory DeregisterOfferResponse.error() {
    return DeregisterOfferResponse(
      status: ResponseStatus.error.value,
      message: 'Offer not deleted',
    );
  }

  final String status;
  final String message;

  @override
  String toString() => JsonEncoder().convert(
        _$DeregisterOfferResponseToJson(this),
      );
}
