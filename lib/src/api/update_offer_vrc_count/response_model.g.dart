// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateOffersVrcCountResponse _$UpdateOffersVrcCountResponseFromJson(
  Map<String, dynamic> json,
) => UpdateOffersVrcCountResponse(
  updatedOffers: (json['updatedOffers'] as List<dynamic>)
      .map((e) => Offer.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$UpdateOffersVrcCountResponseToJson(
  UpdateOffersVrcCountResponse instance,
) => <String, dynamic>{'updatedOffers': instance.updatedOffers};
