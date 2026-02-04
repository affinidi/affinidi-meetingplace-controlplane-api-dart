import 'package:json_annotation/json_annotation.dart';
import '../../core/entity/offer.dart';

part 'response_model.g.dart';

@JsonSerializable()
class UpdateOffersVrcCountResponse {
  UpdateOffersVrcCountResponse({required this.updatedOffers});

  factory UpdateOffersVrcCountResponse.fromJson(Map<String, dynamic> json) =>
      _$UpdateOffersVrcCountResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateOffersVrcCountResponseToJson(this);

  final List<Offer> updatedOffers;
}
