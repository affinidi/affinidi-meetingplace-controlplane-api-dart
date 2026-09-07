// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_error_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletePendingNotificationsErrorResponse
_$DeletePendingNotificationsErrorResponseFromJson(Map<String, dynamic> json) =>
    DeletePendingNotificationsErrorResponse(
      errorCode: json['errorCode'] as String,
      errorMessage: json['errorMessage'] as String,
    );

Map<String, dynamic> _$DeletePendingNotificationsErrorResponseToJson(
  DeletePendingNotificationsErrorResponse instance,
) => <String, dynamic>{
  'errorCode': instance.errorCode,
  'errorMessage': instance.errorMessage,
};
