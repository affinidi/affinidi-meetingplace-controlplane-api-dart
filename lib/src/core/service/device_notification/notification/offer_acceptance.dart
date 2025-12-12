import '../const.dart';
import '../device_notification.dart';
import '../../../entity/notification_item.dart';

class OfferAcceptanceNotification extends DeviceNotification {
  OfferAcceptanceNotification({
    required super.badgeCount,
    required super.data,
    required this.sender,
    required this.offerName,
  }) : super(
         subtitle: 'Invitation accepted!',
         body: '',
         notificationType: NotificationItemType.invitationAccept,
         threadId: NotificationStackGroupingTypes.invitationAccept.value,
       );

  final String offerName;
  final String sender;

  @override
  String getBody() {
    return '$sender wants to connect using $offerName';
  }
}
