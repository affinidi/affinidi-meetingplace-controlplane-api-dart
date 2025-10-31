import '../device_notification.dart';
import '../device_notification_service.dart';

abstract interface class IPayload {
  String build();

  DeviceNotificationData getData();
}

abstract class Platform implements IPlatform {
  IPayload getPayload(DeviceNotification notification);
}
