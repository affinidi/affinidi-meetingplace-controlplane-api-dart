import 'package:aws_kms_api/kms-2014-11-01.dart';

import '../../core/config/env_config.dart';
import '../aws_credentials_manager.dart';
import 'secret_manager.dart';
import 'package:aws_secretsmanager_api/secretsmanager-2017-10-17.dart' as aws;

class AWSSecretManager implements ISecretProvider {
  AWSSecretManager._({
    required String region,
    required AwsClientCredentials credentials,
  }) : _credentials = credentials {
    secretManager = aws.SecretsManager(
      region: region,
      credentials: credentials,
    );
  }

  late aws.SecretsManager secretManager;
  aws.AwsClientCredentials _credentials;

  static Future<AWSSecretManager> init() async {
    final creds = await AwsCredentialsManager.getCredentials();

    final manager = AWSSecretManager._(
      region: getEnv('AWS_REGION'),
      credentials: creds,
    );
    return manager;
  }

  @override
  Future<String> getSecret(String secretId) async {
    final client = await _getClient();
    final aws.GetSecretValueResponse(:secretString) =
        await client.getSecretValue(secretId: secretId);

    if (secretString == null) {
      throw Exception('Secret for id $secretId not found');
    }

    return secretString;
  }

  Future<aws.SecretsManager> _getClient() async {
    final refreshedCredentials =
        await AwsCredentialsManager.refreshCredentialsIfNeeded(_credentials);

    if (refreshedCredentials != null) {
      _credentials = refreshedCredentials;
      secretManager = aws.SecretsManager(
        region: getEnv('AWS_REGION'),
        credentials: refreshedCredentials,
      );
    }
    return secretManager;
  }
}
