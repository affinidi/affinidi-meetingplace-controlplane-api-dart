// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationResponse _$NotificationResponseFromJson(
  Map<String, dynamic> json,
) => NotificationResponse(
  id: json['id'] as String,
  deviceHash: json['deviceHash'] as String,
  did: json['did'] as String,
  payload: json['payload'] as String,
  offerLink: json['offerLink'] as String?,
);

Map<String, dynamic> _$NotificationResponseToJson(
  NotificationResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'deviceHash': instance.deviceHash,
  'did': instance.did,
  'payload': instance.payload,
  'offerLink': instance.offerLink,
};

DeletePendingNotificationsResponse _$DeletePendingNotificationsResponseFromJson(
  Map<String, dynamic> json,
) => DeletePendingNotificationsResponse(
  deletedIds: (json['deletedIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  notifications: (json['notifications'] as List<dynamic>)
      .map((e) => NotificationResponse.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DeletePendingNotificationsResponseToJson(
  DeletePendingNotificationsResponse instance,
) => <String, dynamic>{
  'deletedIds': instance.deletedIds,
  'notifications': instance.notifications,
};
