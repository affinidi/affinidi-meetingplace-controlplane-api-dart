import 'package:meeting_place_mediator/meeting_place_mediator.dart';

import '../../../utils/platform_type.dart';
import '../../logger/logger.dart';
import 'device_notification.dart';
import 'device_notification_exception.dart';
import 'platform/did_comm.dart';
import 'platform/fcm.dart';
import 'push_notification_provider.dart';

class PlatformTypeNotSupported implements Exception {}

abstract interface class IPlatform {
  Future<void> notify({
    required String platformEndpointArn,
    required DeviceNotification notification,
  });

  DeviceNotificationData getDeviceNotificationData(
    DeviceNotification notification,
  );
}

class DeviceNotificationService {
  DeviceNotificationService({
    required Logger logger,
    required PushNotificationProvider provider,
    required MeetingPlaceMediatorSDK mediatorSDK,
  }) : _logger = logger,
       _provider = provider,
       _mediatorSDK = mediatorSDK;

  final Logger _logger;
  final PushNotificationProvider _provider;
  final MeetingPlaceMediatorSDK _mediatorSDK;

  Future<void> notify({
    required PlatformType platformType,
    required String platformEndpointArn,
    required DeviceNotification notification,
  }) {
    try {
      return _getByDevicePlatform(platformType).notify(
        platformEndpointArn: platformEndpointArn,
        notification: notification,
      );
    } catch (e, stackTrace) {
      Error.throwWithStackTrace(
        DeviceNotificationException(e.toString()),
        stackTrace,
      );
    }
  }

  DeviceNotificationData getDeviceNotificationData(
    PlatformType platformType,
    DeviceNotification notification,
  ) {
    return _getByDevicePlatform(
      platformType,
    ).getDeviceNotificationData(notification);
  }

  IPlatform _getByDevicePlatform(PlatformType platformType) {
    switch (platformType) {
      case PlatformType.DIDCOMM:
        return DidComm(mediatorSDK: _mediatorSDK, logger: _logger);
      case PlatformType.PUSH_NOTIFICATION:
        return FCM(provider: _provider);
      default:
        throw PlatformTypeNotSupported();
    }
  }

  Future<String> attemptPlatformRegistration({
    required PlatformType platformType,
    required String deviceToken,
    required String consumerDid,
  }) async {
    final endpointArn = await _provider.createPlatformEndpoint(
      deviceToken: deviceToken,
      metadata: '[Authenticated as ] $consumerDid',
    );

    _logger.info('Received plainform endpoint: $endpointArn');
    return endpointArn!;
  }
}
