import 'dart:convert';

import '../../../config/config.dart';
import '../../../entity/notification_item.dart';
import '../device_notification.dart';
import '../device_notification_service.dart';
import '../push_notification_provider.dart';
import 'platform.dart';

class FCMPayload implements IPayload {
  late Map<String, dynamic> notification;
  late Map<String, dynamic> data;
  late int badgeCount;
  late String notificationTag;

  withNotification({
    required String body,
    required String tag,
    required int badge,
  }) {
    badgeCount = badge;
    notificationTag = tag;
    notification = {
      'title': Config().get('deviceNotification')['title'],
      'body': body,
    };
  }

  withData({
    required NotificationItemType type,
    required DeviceNotificationData data,
  }) {
    final JsonEncoder encoder = JsonEncoder();
    this.data = {
      Config().get('deviceNotification')['pushNotificationCustomKeyProperty']:
          encoder.convert({'type': type.name, 'data': data}),
    };
  }

  @override
  String build() {
    final JsonEncoder encoder = JsonEncoder();
    return encoder.convert({
      'default': notification['body'],
      'GCM': encoder.convert({
        'fcmV1Message': {
          'validate_only': false,
          'message': {
            'notification': notification,
            'data': data,
            'android': {
              'priority': 'high',
              'notification': {
                'channel_id': 'default_channel_id',
                'notification_priority': 'PRIORITY_HIGH',
                'notification_count': badgeCount,
                'sound': 'default',
                'tag': notificationTag,
              },
            },
            'apns': {
              'payload': {
                'aps': {
                  'alert': {
                    'title': notification['title'],
                    'body': notification['body'],
                  },
                  'badge': badgeCount,
                  'sound': 'default',
                },
              },
            },
          },
        },
      }),
    });
  }

  @override
  DeviceNotificationData getData() {
    final key = Config().get(
      'deviceNotification',
    )['pushNotificationCustomKeyProperty'];
    final decodedData = jsonDecode(data[key]) as Map<String, dynamic>;
    final dataMap = decodedData['data'] as Map<String, dynamic>;
    return DeviceNotificationData(
      id: dataMap['id'] as String,
      pendingCount: dataMap['pendingCount'] as int,
    )..notificationDate = dataMap['notificationDate'] as String;
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
        badge: notification.badgeCount,
      )
      ..withData(type: notification.notificationType, data: notification.data);
  }
}
