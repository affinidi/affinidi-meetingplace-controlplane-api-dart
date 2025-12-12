import '../const.dart';
import '../device_notification.dart';
import '../../../entity/notification_item.dart';

class NotifyChannelNotification extends DeviceNotification {
  NotifyChannelNotification({required super.badgeCount, required super.data})
    : super(
        subtitle: '',
        body: '',
        notificationType: NotificationItemType.channelActivity,
        threadId: NotificationStackGroupingTypes.channelActivity.value,
      );

  @override
  String getSubtitle() {
    if (badgeCount == 0) return 'Your contacts are active!';
    return 'Chat message${badgeCount > 1 ? 's' : ''} received';
  }

  @override
  String getBody() {
    if (badgeCount == 0) return 'Check out the updates';
    return 'You have $badgeCount new message${badgeCount > 1 ? 's' : ''}';
  }
}
