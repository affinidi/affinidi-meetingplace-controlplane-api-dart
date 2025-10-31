// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_token_mapping.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceTokenMapping _$DeviceTokenMappingFromJson(Map<String, dynamic> json) =>
    DeviceTokenMapping(
      deviceId: json['deviceId'] as String,
      deviceToken: json['deviceToken'] as String,
      platformType: $enumDecode(_$PlatformTypeEnumMap, json['platformType']),
      platformEndpointArn: json['platformEndpointArn'] as String,
      createdBy: json['createdBy'] as String?,
    )..ttl = json['ttl'] == null ? null : DateTime.parse(json['ttl'] as String);

Map<String, dynamic> _$DeviceTokenMappingToJson(DeviceTokenMapping instance) =>
    <String, dynamic>{
      'ttl': instance.ttl?.toIso8601String(),
      'deviceId': instance.deviceId,
      'deviceToken': instance.deviceToken,
      'platformType': _$PlatformTypeEnumMap[instance.platformType]!,
      'platformEndpointArn': instance.platformEndpointArn,
      'createdBy': instance.createdBy,
    };

const _$PlatformTypeEnumMap = {
  PlatformType.DIDCOMM: 'DIDCOMM',
  PlatformType.PUSH_NOTIFICATION: 'PUSH_NOTIFICATION',
  PlatformType.NONE: 'NONE',
};
