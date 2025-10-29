// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetPendingNotificationsRequest _$GetPendingNotificationsRequestFromJson(
        Map<String, dynamic> json) =>
    GetPendingNotificationsRequest(
      platformType: $enumDecode(_$PlatformTypeEnumMap, json['platformType']),
      deviceToken: json['deviceToken'] as String,
    );

Map<String, dynamic> _$GetPendingNotificationsRequestToJson(
        GetPendingNotificationsRequest instance) =>
    <String, dynamic>{
      'platformType': _$PlatformTypeEnumMap[instance.platformType]!,
      'deviceToken': instance.deviceToken,
    };

const _$PlatformTypeEnumMap = {
  PlatformType.DIDCOMM: 'DIDCOMM',
  PlatformType.PUSH_NOTIFICATION: 'PUSH_NOTIFICATION',
  PlatformType.NONE: 'NONE',
};
