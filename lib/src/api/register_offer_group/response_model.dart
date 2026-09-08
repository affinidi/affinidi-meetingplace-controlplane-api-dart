import 'dart:convert';
import '../../core/entity/group.dart';
import '../../core/entity/offer.dart';
import 'package:json_annotation/json_annotation.dart';

part 'response_model.g.dart';

@JsonSerializable()
class RegisterOfferGroupResponse {
  RegisterOfferGroupResponse({
    required this.offerLink,
    required this.mnemonic,
    required this.validUntil,
    required this.maximumUsage,
    required this.groupId,
  });

  factory RegisterOfferGroupResponse.fromOfferAndGroup(
    Offer offer,
    Group group,
  ) {
    return RegisterOfferGroupResponse(
      offerLink: offer.offerLink,
      mnemonic: offer.mnemonic,
      validUntil: offer.validUntil,
      maximumUsage: offer.maximumClaims,
      groupId: group.id,
    );
  }

  factory RegisterOfferGroupResponse.offerExists() {
    return RegisterOfferGroupResponse(
      offerLink: '',
      mnemonic: '',
      validUntil: null,
      groupId: '',
      maximumUsage: null,
    );
  }

  final String offerLink;
  final String mnemonic;
  final String? validUntil;
  final int? maximumUsage;
  final String groupId;

  @override
  String toString() =>
      JsonEncoder().convert(_$RegisterOfferGroupResponseToJson(this));
}
