// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_error_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeregisterNotificationErrorResponse
_$DeregisterNotificationErrorResponseFromJson(Map<String, dynamic> json) =>
    DeregisterNotificationErrorResponse(
      errorCode: json['errorCode'] as String,
      errorMessage: json['errorMessage'] as String,
    );

Map<String, dynamic> _$DeregisterNotificationErrorResponseToJson(
  DeregisterNotificationErrorResponse instance,
) => <String, dynamic>{
  'errorCode': instance.errorCode,
  'errorMessage': instance.errorMessage,
};
