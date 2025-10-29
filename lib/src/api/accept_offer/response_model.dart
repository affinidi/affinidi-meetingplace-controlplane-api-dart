import 'dart:convert';

import '../../core/entity/offer.dart';
import 'package:json_annotation/json_annotation.dart';

part 'response_model.g.dart';

@JsonSerializable()
class AcceptOfferResponse {
  AcceptOfferResponse({
    required this.didcommMessage,
    required this.offerLink,
    required this.name,
    required this.description,
    required this.vcard,
    required this.validUntil,
    required this.mediatorDid,
    required this.mediatorEndpoint,
    required this.mediatorWSSEndpoint,
  });

  factory AcceptOfferResponse.fromOffer(Offer offer) {
    return AcceptOfferResponse(
      didcommMessage: offer.didcommMessage,
      offerLink: offer.offerLink,
      name: offer.name,
      description: offer.description,
      vcard: offer.vcard,
      validUntil: offer.validUntil,
      mediatorDid: offer.mediatorDid,
      mediatorEndpoint: offer.mediatorEndpoint,
      mediatorWSSEndpoint: offer.mediatorWSSEndpoint,
    );
  }
  final String didcommMessage;
  final String offerLink;
  final String name;
  final String description;
  final String vcard;
  final String? validUntil;
  final String mediatorDid;
  final String mediatorEndpoint;
  final String mediatorWSSEndpoint;

  @override
  String toString() => JsonEncoder().convert(_$AcceptOfferResponseToJson(this));
}
