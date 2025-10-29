// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_error_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotifyOutreachErrorResponse _$NotifyOutreachErrorResponseFromJson(
        Map<String, dynamic> json) =>
    NotifyOutreachErrorResponse(
      errorCode: json['errorCode'] as String,
      errorMessage: json['errorMessage'] as String,
    );

Map<String, dynamic> _$NotifyOutreachErrorResponseToJson(
        NotifyOutreachErrorResponse instance) =>
    <String, dynamic>{
      'errorCode': instance.errorCode,
      'errorMessage': instance.errorMessage,
    };
