// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_error_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthAuthenticateErrorResponse _$AuthAuthenticateErrorResponseFromJson(
        Map<String, dynamic> json) =>
    AuthAuthenticateErrorResponse(
      errorCode: json['errorCode'] as String,
      error: json['error'] as String,
      issue: json['issue'] as String,
    );

Map<String, dynamic> _$AuthAuthenticateErrorResponseToJson(
        AuthAuthenticateErrorResponse instance) =>
    <String, dynamic>{
      'errorCode': instance.errorCode,
      'error': instance.error,
      'issue': instance.issue,
    };
