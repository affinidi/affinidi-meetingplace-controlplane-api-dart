// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_channel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationChannel _$NotificationChannelFromJson(Map<String, dynamic> json) =>
    NotificationChannel(
        notificationChannelId: json['notificationChannelId'] as String,
        did: json['did'] as String,
        peerDid: json['peerDid'] as String,
        platformEndpointArn: json['platformEndpointArn'] as String,
        platformType: $enumDecode(_$PlatformTypeEnumMap, json['platformType']),
        createdBy: json['createdBy'] as String,
      )
      ..ttl = json['ttl'] == null ? null : DateTime.parse(json['ttl'] as String)
      ..modifiedBy = json['modifiedBy'] as String;

Map<String, dynamic> _$NotificationChannelToJson(
  NotificationChannel instance,
) => <String, dynamic>{
  'ttl': instance.ttl?.toIso8601String(),
  'notificationChannelId': instance.notificationChannelId,
  'did': instance.did,
  'peerDid': instance.peerDid,
  'platformEndpointArn': instance.platformEndpointArn,
  'platformType': _$PlatformTypeEnumMap[instance.platformType]!,
  'createdBy': instance.createdBy,
  'modifiedBy': instance.modifiedBy,
};

const _$PlatformTypeEnumMap = {
  PlatformType.DIDCOMM: 'DIDCOMM',
  PlatformType.PUSH_NOTIFICATION: 'PUSH_NOTIFICATION',
  PlatformType.NONE: 'NONE',
};
