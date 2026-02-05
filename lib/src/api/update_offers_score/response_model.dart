import 'package:json_annotation/json_annotation.dart';
import '../../core/entity/offer.dart';

part 'response_model.g.dart';

@JsonSerializable()
class UpdateOffersScoreResponse {
  UpdateOffersScoreResponse({
    required this.updatedOffers,
    required this.failedOffers,
  });

  factory UpdateOffersScoreResponse.fromJson(Map<String, dynamic> json) =>
      _$UpdateOffersScoreResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateOffersScoreResponseToJson(this);

  final List<Offer> updatedOffers;
  final List<FailedOffer> failedOffers;
}

@JsonSerializable()
class FailedOffer {
  FailedOffer({required this.mnemonic, required this.reason});

  factory FailedOffer.fromJson(Map<String, dynamic> json) =>
      _$FailedOfferFromJson(json);

  Map<String, dynamic> toJson() => _$FailedOfferToJson(this);

  final String mnemonic;
  final String reason;
}
