// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterOfferResponse _$RegisterOfferResponseFromJson(
  Map<String, dynamic> json,
) => RegisterOfferResponse(
  offerLink: json['offerLink'] as String,
  mnemonic: json['mnemonic'] as String,
  validUntil: json['validUntil'] as String?,
  maximumUsage: (json['maximumUsage'] as num?)?.toInt(),
  score: (json['score'] as num?)?.toInt(),
);

Map<String, dynamic> _$RegisterOfferResponseToJson(
  RegisterOfferResponse instance,
) => <String, dynamic>{
  'offerLink': instance.offerLink,
  'mnemonic': instance.mnemonic,
  'validUntil': instance.validUntil,
  'maximumUsage': instance.maximumUsage,
  'score': instance.score,
};
