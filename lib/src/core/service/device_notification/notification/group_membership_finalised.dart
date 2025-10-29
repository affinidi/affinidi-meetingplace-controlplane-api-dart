import '../const.dart';
import '../device_notification.dart';
import '../../../entity/notification_item.dart';

class GroupMembershipFinalisedNotification extends DeviceNotification {
  GroupMembershipFinalisedNotification({
    required super.badgeCount,
    required super.data,
  }) : super(
          subtitle: 'Connection completed!',
          body: 'Group membership request approved',
          notificationType: NotificationItemType.groupMembershipFinalised,
          threadId:
              NotificationStackGroupingTypes.groupMembershipFinalised.value,
        );
}
