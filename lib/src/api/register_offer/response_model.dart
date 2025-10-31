import 'dart:convert';
import '../../core/entity/offer.dart';
import 'package:json_annotation/json_annotation.dart';

part 'response_model.g.dart';

@JsonSerializable()
class RegisterOfferResponse {
  RegisterOfferResponse({
    required this.offerLink,
    required this.mnemonic,
    this.validUntil,
    this.maximumUsage,
  });

  factory RegisterOfferResponse.fromOffer(Offer offer) {
    return RegisterOfferResponse(
      offerLink: offer.offerLink,
      mnemonic: offer.mnemonic,
      validUntil: offer.validUntil,
      maximumUsage: offer.maximumClaims,
    );
  }

  factory RegisterOfferResponse.offerExists() {
    return RegisterOfferResponse(
      offerLink: '',
      mnemonic: '',
      validUntil: null,
      maximumUsage: null,
    );
  }
  final String offerLink;
  final String mnemonic;
  final String? validUntil;
  final int? maximumUsage;

  @override
  String toString() => JsonEncoder().convert(
        _$RegisterOfferResponseToJson(this),
      );
}
