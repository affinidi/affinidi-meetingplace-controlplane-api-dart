// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateOffersScoreResponse _$UpdateOffersScoreResponseFromJson(
  Map<String, dynamic> json,
) => UpdateOffersScoreResponse(
  updatedOffers: (json['updatedOffers'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  failedOffers: (json['failedOffers'] as List<dynamic>)
      .map((e) => FailedOffer.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$UpdateOffersScoreResponseToJson(
  UpdateOffersScoreResponse instance,
) => <String, dynamic>{
  'updatedOffers': instance.updatedOffers,
  'failedOffers': instance.failedOffers,
};

FailedOffer _$FailedOfferFromJson(Map<String, dynamic> json) => FailedOffer(
  mnemonic: json['mnemonic'] as String,
  reason: json['reason'] as String,
);

Map<String, dynamic> _$FailedOfferToJson(FailedOffer instance) =>
    <String, dynamic>{'mnemonic': instance.mnemonic, 'reason': instance.reason};
