// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_error_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotifyChannelGroupErrorResponse _$NotifyChannelGroupErrorResponseFromJson(
  Map<String, dynamic> json,
) => NotifyChannelGroupErrorResponse(
  errorCode: json['errorCode'] as String,
  errorMessage: json['errorMessage'] as String,
);

Map<String, dynamic> _$NotifyChannelGroupErrorResponseToJson(
  NotifyChannelGroupErrorResponse instance,
) => <String, dynamic>{
  'errorCode': instance.errorCode,
  'errorMessage': instance.errorMessage,
};
