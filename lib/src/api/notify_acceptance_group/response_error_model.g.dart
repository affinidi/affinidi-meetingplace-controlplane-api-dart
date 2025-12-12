// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_error_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotifyAcceptanceGroupErrorResponse _$NotifyAcceptanceGroupErrorResponseFromJson(
  Map<String, dynamic> json,
) => NotifyAcceptanceGroupErrorResponse(
  errorCode: json['errorCode'] as String,
  errorMessage: json['errorMessage'] as String,
);

Map<String, dynamic> _$NotifyAcceptanceGroupErrorResponseToJson(
  NotifyAcceptanceGroupErrorResponse instance,
) => <String, dynamic>{
  'errorCode': instance.errorCode,
  'errorMessage': instance.errorMessage,
};
