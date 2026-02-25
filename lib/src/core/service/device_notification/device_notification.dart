import '../../entity/notification_item.dart';
import '../../../utils/date_time.dart';
import 'package:json_annotation/json_annotation.dart';

part 'device_notification.g.dart';

@JsonSerializable()
class DeviceNotificationData {
  DeviceNotificationData({required this.id, required this.pendingCount}) {
    notificationDate = nowUtc().toIso8601String();
  }
  final String id;
  final int pendingCount;
  late String notificationDate;

  Map<String, dynamic> toJson() => _$DeviceNotificationDataToJson(this);
}

class DeviceNotification {
  DeviceNotification({
    required subtitle,
    required body,
    required this.notificationType,
    required this.badgeCount,
    required this.threadId,
    required this.data,
  }) {
    _subtitle = subtitle;
    _body = body;
    notificationDate = nowUtc().toIso8601String();
  }
  final NotificationItemType notificationType;
  final DeviceNotificationData data;

  late String _subtitle;
  late String _body;
  late String notificationDate;
  late int badgeCount;
  late String threadId;

  String getSubtitle() {
    return _subtitle;
  }

  String getBody() {
    return _body;
  }
}
