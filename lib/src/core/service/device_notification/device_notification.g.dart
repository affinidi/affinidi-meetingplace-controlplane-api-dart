// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceNotificationData _$DeviceNotificationDataFromJson(
  Map<String, dynamic> json,
) => DeviceNotificationData(
  id: json['id'] as String,
  pendingCount: (json['pendingCount'] as num).toInt(),
)..notificationDate = json['notificationDate'] as String;

Map<String, dynamic> _$DeviceNotificationDataToJson(
  DeviceNotificationData instance,
) => <String, dynamic>{
  'id': instance.id,
  'pendingCount': instance.pendingCount,
  'notificationDate': instance.notificationDate,
};
