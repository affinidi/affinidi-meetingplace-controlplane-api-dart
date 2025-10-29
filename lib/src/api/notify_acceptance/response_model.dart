import 'dart:convert';
import '../../core/entity/notification_item.dart';
import 'package:json_annotation/json_annotation.dart';

part 'response_model.g.dart';

@JsonSerializable()
class NotifyChannelResponse {
  NotifyChannelResponse({required this.notificationId});

  factory NotifyChannelResponse.fromNotificationItem(
    NotificationItem notificationItem,
  ) {
    return NotifyChannelResponse(notificationId: notificationItem.getId());
  }
  final String? notificationId;

  @override
  String toString() =>
      JsonEncoder().convert(_$NotifyChannelResponseToJson(this));
}
