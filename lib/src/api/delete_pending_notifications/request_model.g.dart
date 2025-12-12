// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletePendingNotificationsRequest _$DeletePendingNotificationsRequestFromJson(
  Map<String, dynamic> json,
) => DeletePendingNotificationsRequest(
  deviceToken: json['deviceToken'] as String,
  platformType: $enumDecode(_$PlatformTypeEnumMap, json['platformType']),
  notificationIds: (json['notificationIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$DeletePendingNotificationsRequestToJson(
  DeletePendingNotificationsRequest instance,
) => <String, dynamic>{
  'deviceToken': instance.deviceToken,
  'platformType': _$PlatformTypeEnumMap[instance.platformType]!,
  'notificationIds': instance.notificationIds,
};

const _$PlatformTypeEnumMap = {
  PlatformType.DIDCOMM: 'DIDCOMM',
  PlatformType.PUSH_NOTIFICATION: 'PUSH_NOTIFICATION',
  PlatformType.NONE: 'NONE',
};
