// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_error_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateOffersScoreErrorResponse _$UpdateOffersScoreErrorResponseFromJson(
  Map<String, dynamic> json,
) => UpdateOffersScoreErrorResponse(
  errorCode: json['errorCode'] as String,
  errorMessage: json['errorMessage'] as String,
);

Map<String, dynamic> _$UpdateOffersScoreErrorResponseToJson(
  UpdateOffersScoreErrorResponse instance,
) => <String, dynamic>{
  'errorCode': instance.errorCode,
  'errorMessage': instance.errorMessage,
};
