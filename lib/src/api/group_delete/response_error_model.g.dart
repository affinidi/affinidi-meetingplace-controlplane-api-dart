// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_error_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupDeleteErrorResponse _$GroupDeleteErrorResponseFromJson(
        Map<String, dynamic> json) =>
    GroupDeleteErrorResponse(
      errorCode: json['errorCode'] as String,
      errorMessage: json['errorMessage'] as String,
    );

Map<String, dynamic> _$GroupDeleteErrorResponseToJson(
        GroupDeleteErrorResponse instance) =>
    <String, dynamic>{
      'errorCode': instance.errorCode,
      'errorMessage': instance.errorMessage,
    };
