import '../../entity/offer.dart';
import '../../../utils/platform_type.dart';
import 'package:json_annotation/json_annotation.dart';

part 'register_offer_input.g.dart';

@JsonSerializable()
class RegisterOfferInput {
  RegisterOfferInput({
    required this.offerName,
    required this.offerDescription,
    required this.offerType,
    required this.didcommMessage,
    required this.vcard,
    required this.deviceToken,
    required this.platformType,
    required this.mediatorDid,
    required this.mediatorEndpoint,
    required this.mediatorWSSEndpoint,
    required this.contactAttributes,
    this.validUntil,
    this.maximumUsage,
    this.customPhrase,
    this.metadata,
  });

  factory RegisterOfferInput.fromJson(Map<String, dynamic> json) =>
      _$RegisterOfferInputFromJson(json);

  final String offerName;
  final String offerDescription;
  final OfferType offerType;
  final String didcommMessage;
  final String vcard;
  final String deviceToken;
  final PlatformType platformType;
  final String mediatorDid;
  final String mediatorEndpoint;
  final String mediatorWSSEndpoint;
  final int contactAttributes;
  final String? validUntil;
  final int? maximumUsage;
  final String? customPhrase;
  final String? metadata;
}
