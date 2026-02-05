// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateOffersScoreResponse _$UpdateOffersScoreResponseFromJson(
  Map<String, dynamic> json,
) => UpdateOffersScoreResponse(
  updatedOffers: (json['updatedOffers'] as List<dynamic>)
      .map((e) => Offer.fromJson(e as Map<String, dynamic>))
      .toList(),
  unauthorizedMnemonics: (json['unauthorizedMnemonics'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$UpdateOffersScoreResponseToJson(
  UpdateOffersScoreResponse instance,
) => <String, dynamic>{
  'updatedOffers': instance.updatedOffers,
  'unauthorizedMnemonics': instance.unauthorizedMnemonics,
};
