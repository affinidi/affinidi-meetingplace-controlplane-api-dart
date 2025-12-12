// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotifyChannelRequest _$NotifyChannelRequestFromJson(
  Map<String, dynamic> json,
) => NotifyChannelRequest(
  notificationChannelId: json['notificationChannelId'] as String,
  did: json['did'] as String,
  type: json['type'] as String,
);

Map<String, dynamic> _$NotifyChannelRequestToJson(
  NotifyChannelRequest instance,
) => <String, dynamic>{
  'notificationChannelId': instance.notificationChannelId,
  'did': instance.did,
  'type': instance.type,
};
