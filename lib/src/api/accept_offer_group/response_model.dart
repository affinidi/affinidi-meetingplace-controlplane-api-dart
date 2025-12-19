import 'dart:convert';

import '../../core/entity/offer.dart';
import 'package:json_annotation/json_annotation.dart';

part 'response_model.g.dart';

@JsonSerializable()
class AcceptOfferGroupResponse {
  AcceptOfferGroupResponse({
    required this.didcommMessage,
    required this.offerLink,
    required this.name,
    required this.description,
    required this.contactCard,
    required this.validUntil,
    required this.mediatorDid,
    required this.mediatorEndpoint,
    required this.mediatorWSSEndpoint,
    required this.metadata,
  });

  factory AcceptOfferGroupResponse.fromOffer(Offer offer) {
    return AcceptOfferGroupResponse(
      didcommMessage: offer.didcommMessage,
      offerLink: offer.offerLink,
      name: offer.name,
      description: offer.description,
      contactCard: offer.contactCard,
      validUntil: offer.validUntil,
      mediatorDid: offer.mediatorDid,
      mediatorEndpoint: offer.mediatorEndpoint,
      mediatorWSSEndpoint: offer.mediatorWSSEndpoint,
      metadata: offer.metadata,
    );
  }
  final String didcommMessage;
  final String offerLink;
  final String name;
  final String description;
  final String contactCard;
  final String? validUntil;
  final String mediatorDid;
  final String mediatorEndpoint;
  final String mediatorWSSEndpoint;
  final String? metadata;

  @override
  String toString() =>
      JsonEncoder().convert(_$AcceptOfferGroupResponseToJson(this));
}
