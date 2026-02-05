import 'package:json_annotation/json_annotation.dart';
import '../../core/entity/offer.dart';

part 'response_model.g.dart';

@JsonSerializable()
class UpdateOffersScoreResponse {
  UpdateOffersScoreResponse({
    required this.updatedOffers,
    required this.unauthorizedMnemonics,
  });

  factory UpdateOffersScoreResponse.fromJson(Map<String, dynamic> json) =>
      _$UpdateOffersScoreResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateOffersScoreResponseToJson(this);

  final List<Offer> updatedOffers;
  final List<String> unauthorizedMnemonics;
}
