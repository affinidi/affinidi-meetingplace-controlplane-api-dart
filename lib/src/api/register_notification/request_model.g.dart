// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterNotificationRequest _$RegisterNotificationRequestFromJson(
        Map<String, dynamic> json) =>
    RegisterNotificationRequest(
      myDid: json['myDid'] as String,
      theirDid: json['theirDid'] as String,
      deviceToken: json['deviceToken'] as String,
      platformType: $enumDecode(_$PlatformTypeEnumMap, json['platformType']),
    );

Map<String, dynamic> _$RegisterNotificationRequestToJson(
        RegisterNotificationRequest instance) =>
    <String, dynamic>{
      'myDid': instance.myDid,
      'theirDid': instance.theirDid,
      'deviceToken': instance.deviceToken,
      'platformType': _$PlatformTypeEnumMap[instance.platformType]!,
    };

const _$PlatformTypeEnumMap = {
  PlatformType.DIDCOMM: 'DIDCOMM',
  PlatformType.PUSH_NOTIFICATION: 'PUSH_NOTIFICATION',
  PlatformType.NONE: 'NONE',
};
