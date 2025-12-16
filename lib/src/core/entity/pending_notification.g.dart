// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PendingNotification _$PendingNotificationFromJson(Map<String, dynamic> json) =>
    PendingNotification(
      ttl: json['ttl'] == null ? null : DateTime.parse(json['ttl'] as String),
      id: json['id'] as String,
      deviceHash: json['deviceHash'] as String,
    );

Map<String, dynamic> _$PendingNotificationToJson(
  PendingNotification instance,
) => <String, dynamic>{
  'ttl': instance.ttl?.toIso8601String(),
  'id': instance.id,
  'deviceHash': instance.deviceHash,
};
