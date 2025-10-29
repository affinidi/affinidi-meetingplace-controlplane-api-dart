import '../const.dart';
import '../device_notification.dart';
import '../../../entity/notification_item.dart';

class OfferAcceptanceGroupNotification extends DeviceNotification {
  OfferAcceptanceGroupNotification({
    required super.badgeCount,
    required super.data,
    required this.offerName,
  }) : super(
          subtitle: 'Invitation accepted!',
          body: 'Request to join $offerName has been accepted',
          notificationType: NotificationItemType.invitationGroupAccept,
          threadId: NotificationStackGroupingTypes.invitationAccept.value,
        );

  final String offerName;
}
