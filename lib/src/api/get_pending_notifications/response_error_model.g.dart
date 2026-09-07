// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_error_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetPendingNotificationsErrorResponse
_$GetPendingNotificationsErrorResponseFromJson(Map<String, dynamic> json) =>
    GetPendingNotificationsErrorResponse(
      errorCode: json['errorCode'] as String,
      errorMessage: json['errorMessage'] as String,
    );

Map<String, dynamic> _$GetPendingNotificationsErrorResponseToJson(
  GetPendingNotificationsErrorResponse instance,
) => <String, dynamic>{
  'errorCode': instance.errorCode,
  'errorMessage': instance.errorMessage,
};
