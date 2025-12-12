import '../const.dart';
import '../device_notification.dart';
import '../../../entity/notification_item.dart';

class OfferFinalisedDeviceNotification extends DeviceNotification {
  OfferFinalisedDeviceNotification({
    required super.badgeCount,
    required super.data,
  }) : super(
         subtitle: 'Connection completed!',
         body: 'Connection request approved!',
         notificationType: NotificationItemType.offerFinalised,
         threadId: NotificationStackGroupingTypes.offerFinalised.value,
       );
}
