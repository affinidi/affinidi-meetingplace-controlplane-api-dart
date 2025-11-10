import 'dart:convert';
import '../../../config/config.dart';
import '../../../config/env_config.dart';
import '../push_notification_provider.dart';
import '../device_notification.dart';
import '../device_notification_service.dart';
import '../../../entity/notification_item.dart';
import 'platform.dart';

class FCMPayload implements IPayload {
  late Map<String, dynamic> notification;
  late Map<String, dynamic> data;
  late int badgeCount;

  withNotification({
    required String body,
    required String tag,
    required int badge,
  }) {
    badgeCount = badge;
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
      }
    };
  }

  @override
  String build() {
    final JsonEncoder encoder = JsonEncoder();
    return encoder.convert({
      'GCM': encoder.convert({
        'fcmV1Message': {
          'message': {
            'notification': notification,
            'data': data,
            'apns': {
              'payload': {
                'aps': {
                  'badge': badgeCount,
                }
              }
            },
            'android': {
              'notification': {
                'notification_count': badgeCount,
              }
            },
          }
        }
      })
    });
  }

  @override
  DeviceNotificationData getData() {
    final key =
        Config().get('deviceNotification')['pushNotificationCustomKeyProperty'];
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
  String getPlatformArn() {
    return getEnv('AWS_PLATFORM_APPLICATION_ARN');
  }

  @override
  FCMPayload getPayload(DeviceNotification notification) {
    return FCMPayload()
      ..withNotification(
        body: notification.getBody(),
        tag: notification.threadId,
        badge: notification.badgeCount,
      )
      ..withData(
        type: notification.notificationType,
        data: notification.data,
      );
  }
}
