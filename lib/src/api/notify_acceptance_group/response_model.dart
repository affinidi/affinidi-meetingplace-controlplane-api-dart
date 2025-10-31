import 'dart:convert';
import '../../core/entity/notification_item.dart';
import 'package:json_annotation/json_annotation.dart';

part 'response_model.g.dart';

@JsonSerializable()
class NotifyAcceptanceGroupResponse {
  NotifyAcceptanceGroupResponse({required this.notificationId});

  factory NotifyAcceptanceGroupResponse.fromNotificationItem(
    NotificationItem notificationItem,
  ) {
    return NotifyAcceptanceGroupResponse(
        notificationId: notificationItem.getId());
  }
  final String? notificationId;

  @override
  String toString() => jsonEncode(_$NotifyAcceptanceGroupResponseToJson(this));
}
