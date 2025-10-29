import '../const.dart';
import '../device_notification.dart';
import '../../../entity/notification_item.dart';

class NotifyInvitationOutreachNotification extends DeviceNotification {
  NotifyInvitationOutreachNotification({
    required super.badgeCount,
    required super.data,
    required String sender,
  }) : super(
          subtitle: 'Request to connect',
          body: '$sender has invited you to connect with them',
          notificationType: NotificationItemType.invitationOutreach,
          threadId: NotificationStackGroupingTypes.invitationOutreach.value,
        );
}
