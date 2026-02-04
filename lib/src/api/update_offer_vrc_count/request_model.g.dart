// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateOffersVrcCountRequest _$UpdateOffersVrcCountRequestFromJson(
  Map<String, dynamic> json,
) => UpdateOffersVrcCountRequest(
  score: (json['score'] as num).toInt(),
  offerLinks: (json['offerLinks'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$UpdateOffersVrcCountRequestToJson(
  UpdateOffersVrcCountRequest instance,
) => <String, dynamic>{
  'score': instance.score,
  'offerLinks': instance.offerLinks,
};
