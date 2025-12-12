// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationResponse _$NotificationResponseFromJson(
  Map<String, dynamic> json,
) => NotificationResponse(
  id: json['id'] as String,
  type: json['type'] as String,
  payload: json['payload'] as String,
  notificationDate: json['notificationDate'] as String,
);

Map<String, dynamic> _$NotificationResponseToJson(
  NotificationResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'payload': instance.payload,
  'notificationDate': instance.notificationDate,
};

GetPendingNotificationsResponse _$GetPendingNotificationsResponseFromJson(
  Map<String, dynamic> json,
) => GetPendingNotificationsResponse(
  notifications: (json['notifications'] as List<dynamic>)
      .map((e) => NotificationResponse.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GetPendingNotificationsResponseToJson(
  GetPendingNotificationsResponse instance,
) => <String, dynamic>{
  'notifications': instance.notifications.map((e) => e.toJson()).toList(),
};
