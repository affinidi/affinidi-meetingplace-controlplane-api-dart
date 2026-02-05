// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateOffersScoreRequest _$UpdateOffersScoreRequestFromJson(
  Map<String, dynamic> json,
) => UpdateOffersScoreRequest(
  score: (json['score'] as num).toInt(),
  offerLinks: (json['offerLinks'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$UpdateOffersScoreRequestToJson(
  UpdateOffersScoreRequest instance,
) => <String, dynamic>{
  'score': instance.score,
  'offerLinks': instance.offerLinks,
};
