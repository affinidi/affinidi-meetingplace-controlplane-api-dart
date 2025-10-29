import 'dart:convert';
import '../../core/entity/notification_item.dart';
import 'package:json_annotation/json_annotation.dart';

part 'response_model.g.dart';

@JsonSerializable()
class NotificationResponse {
  NotificationResponse({
    required this.id,
    required this.type,
    required this.payload,
    required this.notificationDate,
  });
  final String id;
  final String type;
  final String payload;
  final String notificationDate;

  static NotificationResponse fromJson(Map<String, dynamic> json) {
    return _$NotificationResponseFromJson(json);
  }

  toJson() => _$NotificationResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class GetPendingNotificationsResponse {
  GetPendingNotificationsResponse({
    required this.notifications,
  });

  factory GetPendingNotificationsResponse.fromPendingNotifications(
    List<NotificationItem> notificationItems,
  ) {
    return GetPendingNotificationsResponse(
      notifications: notificationItems
          .map(
            (item) => NotificationResponse(
              id: item.id,
              type: item.type.value,
              payload: item.payload,
              notificationDate: item.createdAt,
            ),
          )
          .toList(),
    );
  }
  final List<NotificationResponse> notifications;

  @override
  String toString() => JsonEncoder().convert(
        _$GetPendingNotificationsResponseToJson(this),
      );
}
