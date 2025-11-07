import 'dart:convert';
import '../../../config/config.dart';
import '../push_notification_provider.dart';
import '../device_notification.dart';
import '../device_notification_service.dart';
import '../../../entity/notification_item.dart';
import 'platform.dart';

class FCMPayload implements IPayload {
  late Map<String, dynamic> notification;
  late Map<String, dynamic> data;

  withNotification({required String body, required String tag}) {
    notification = {
      'title': Config().get('deviceNotification')['title'],
      'body': body,
      'tag': tag,
    };
  }

  withData({
    required NotificationItemType type,
    required DeviceNotificationData data,
  }) {
    this.data = {
      Config().get('deviceNotification')['pushNotificationCustomKeyProperty']: {
        'type': type.name,
        'data': data,
      },
    };
  }

  @override
  String build() {
    final JsonEncoder encoder = JsonEncoder();
    return encoder.convert({
      'GCM': encoder.convert({'notification': notification, 'data': data}),
    });
  }

  @override
  DeviceNotificationData getData() {
    final key = Config().get(
      'deviceNotification',
    )['pushNotificationCustomKeyProperty'];
    return data[key]['data'];
  }
}

class FCM extends Platform implements IPlatform {
  FCM({required PushNotificationProvider provider}) : _provider = provider;

  final PushNotificationProvider _provider;

  @override
  Future<DeviceNotificationData> notify({
    required String platformEndpointArn,
    required DeviceNotification notification,
  }) async {
    final payload = getPayload(notification);

    await _provider.send(
      targetArn: platformEndpointArn,
      payload: payload.build(),
    );

    return payload.getData();
  }

  @override
  FCMPayload getPayload(DeviceNotification notification) {
    return FCMPayload()
      ..withNotification(
        body: notification.getBody(),
        tag: notification.threadId,
      )
      ..withData(type: notification.notificationType, data: notification.data);
  }
}
