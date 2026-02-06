// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateOffersScoreRequest _$UpdateOffersScoreRequestFromJson(
  Map<String, dynamic> json,
) => UpdateOffersScoreRequest(
  score: (json['score'] as num).toInt(),
  mnemonics: (json['mnemonics'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$UpdateOffersScoreRequestToJson(
  UpdateOffersScoreRequest instance,
) => <String, dynamic>{
  'score': instance.score,
  'mnemonics': instance.mnemonics,
};
