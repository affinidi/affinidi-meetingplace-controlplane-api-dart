// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_error_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupNotifyChannelErrorResponse _$GroupNotifyChannelErrorResponseFromJson(
  Map<String, dynamic> json,
) => GroupNotifyChannelErrorResponse(
  errorCode: json['errorCode'] as String,
  errorMessage: json['errorMessage'] as String,
);

Map<String, dynamic> _$GroupNotifyChannelErrorResponseToJson(
  GroupNotifyChannelErrorResponse instance,
) => <String, dynamic>{
  'errorCode': instance.errorCode,
  'errorMessage': instance.errorMessage,
};
