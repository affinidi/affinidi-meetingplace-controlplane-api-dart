import 'dart:convert';
import '../../core/entity/offer.dart';
import 'package:json_annotation/json_annotation.dart';

part 'response_model.g.dart';

@JsonSerializable()
class QueryOfferResponse {
  QueryOfferResponse({
    required this.offerLink,
    required this.name,
    required this.description,
    required this.vcard,
    required this.validUntil,
    required this.maximumUsage,
    required this.mediatorDid,
    required this.mediatorEndpoint,
    required this.mediatorWSSEndpoint,
    required this.didcommMessage,
    required this.status,
    required this.contactAttributes,
    required this.groupId,
    required this.groupDid,
  });

  factory QueryOfferResponse.fromOffer(Offer offer) {
    return QueryOfferResponse(
      offerLink: offer.offerLink,
      name: offer.name,
      description: offer.description,
      vcard: offer.vcard,
      validUntil: offer.validUntil,
      maximumUsage: offer.maximumClaims,
      mediatorDid: offer.mediatorDid,
      mediatorEndpoint: offer.mediatorEndpoint,
      mediatorWSSEndpoint: offer.mediatorWSSEndpoint,
      didcommMessage: offer.didcommMessage,
      status: offer.status.value,
      contactAttributes: offer.contactAttributes,
      groupId: offer.groupId,
      groupDid: offer.groupDid,
    );
  }
  final String offerLink;
  final String name;
  final String description;
  final String vcard;
  final String mediatorDid;
  final String mediatorEndpoint;
  final String mediatorWSSEndpoint;
  final String didcommMessage;
  final String status;
  final int contactAttributes;
  final String? validUntil;
  final int? maximumUsage;
  final String? groupId;
  final String? groupDid;

  @override
  String toString() => jsonEncode(_$QueryOfferResponseToJson(this));
}
