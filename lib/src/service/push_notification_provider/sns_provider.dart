import '../../core/logger/logger.dart';
import '../../core/service/device_notification/push_notification_exception.dart';
import '../credentials_manager/aws_credentials_manager.dart';
import '../../core/config/env_config.dart';
import '../../core/service/device_notification/push_notification_provider.dart';

import 'package:aws_sns_api/sns-2010-03-31.dart' as sns;

class SNSProvider implements PushNotificationProvider {
  SNSProvider._({
    required String region,
    required sns.AwsClientCredentials credentials,
    required Logger logger,
  }) : _credentials = credentials,
       _logger = logger {
    snsClient = sns.SNS(region: region, credentials: credentials);
  }

  final Logger _logger;
  late sns.SNS snsClient;
  sns.AwsClientCredentials? _credentials;

  static Future<SNSProvider> init({required Logger logger}) async {
    final creds = await AwsCredentialsManager.getCredentials();

    final manager = SNSProvider._(
      region: getEnv('AWS_REGION'),
      credentials: creds,
      logger: logger,
    );
    return manager;
  }

  @override
  Future<String> createPlatformEndpoint({
    required String deviceToken,
    String? metadata,
  }) async {
    try {
      final client = await _getClient();
      final sns.CreateEndpointResponse(:endpointArn) = await client
          .createPlatformEndpoint(
            platformApplicationArn: getEnv('AWS_PLATFORM_APPLICATION_ARN'),
            token: deviceToken,
            customUserData: metadata,
          );

      if (endpointArn == null) {
        throw Exception('Received endpoint arn is empty');
      }
      return endpointArn;
    } catch (e) {
      _logger.error('Platform endpoint creation failed: $e');
      throw PlatformEndpointCreationFailed(e);
    }
  }

  @override
  Future<void> send({
    required String targetArn,
    required String payload,
  }) async {
    final client = await _getClient();

    _logger.debug(
      'Send push notification to ARN: $targetArn using payload: $payload',
    );
    final response = await client.publish(
      message: payload,
      targetArn: targetArn,
      messageStructure: 'json',
    );

    _logger.debug(
      'Push notification triggered successfully for ARN: $targetArn using payload: $payload',
    );
    _logger.info('Publishing success, messsage id: ${response.messageId}');
  }

  Future<sns.SNS> _getClient() async {
    final refreshedCredentials =
        await AwsCredentialsManager.refreshCredentialsIfNeeded(_credentials);

    if (refreshedCredentials != null) {
      _credentials = refreshedCredentials;
      snsClient = sns.SNS(
        region: getEnv('AWS_REGION'),
        credentials: refreshedCredentials,
      );
    }
    return snsClient;
  }
}
