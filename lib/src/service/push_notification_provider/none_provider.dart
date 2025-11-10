import '../../core/logger/logger.dart';
import '../../core/service/device_notification/push_notification_provider.dart';
import 'package:uuid/uuid.dart';

class NoneProvider implements PushNotificationProvider {
  NoneProvider({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  Future<String> createPlatformEndpoint({
    required String deviceToken,
    String? metadata,
  }) async {
    _logger.info(
      'Push notification provider: none, skip platform registration',
    );
    return 'none:${Uuid().v4()}';
  }

  @override
  Future<void> send({
    required String targetArn,
    required String payload,
  }) async {
    _logger.info('Push notification provider: none, skip sending notification');
    return;
  }
}
