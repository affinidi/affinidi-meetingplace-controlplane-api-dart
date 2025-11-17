import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_aws_api/shared.dart' as shared;

import '../../core/config/env_config.dart';

class AwsCredentialsManager {
  static Future<shared.AwsClientCredentials> getCredentials() {
    final serverType = getEnv('SERVER_TYPE');

    if (serverType == 'local') {
      return fromEnv();
    }

    if (serverType == 'fargate') {
      return fetchFargateCredentials();
    }

    throw Exception('Unsupported server type $serverType');
  }

  /// Fetches temporary credentials from the ECS Task Role endpoint in Fargate.
  ///
  /// Returns [shared.AwsClientCredentials]
  static Future<shared.AwsClientCredentials> fetchFargateCredentials() async {
    final relativeUri =
        Platform.environment['AWS_CONTAINER_CREDENTIALS_RELATIVE_URI'];

    if (relativeUri == null) {
      throw Exception(
        '''AWS_CONTAINER_CREDENTIALS_RELATIVE_URI is not set. Task role not available.''',
      );
    }

    final url = Uri.parse('http://169.254.170.2$relativeUri');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch credentials: ${response.body}');
    }

    final data = jsonDecode(response.body);

    return shared.AwsClientCredentials(
      accessKey: data['AccessKeyId'],
      secretKey: data['SecretAccessKey'],
      sessionToken: data['Token'],
      expiration: DateTime.parse(data['Expiration']),
    );
  }

  static Future<shared.AwsClientCredentials> fromEnv() async {
    final profile = getEnvOrNull('AWS_PROFILE');

    if (profile != null) {
      return await fromAwsProfile(profile);
    }

    return shared.AwsClientCredentials(
      accessKey: getEnv('AWS_ACCESS_KEY'),
      secretKey: getEnv('AWS_SECRET_KEY'),
      sessionToken: getEnv('AWS_SESSION_TOKEN'),
      expiration: DateTime.now().add(const Duration(hours: 1)),
    );
  }

  static Future<shared.AwsClientCredentials> fromAwsProfile(
    String profile,
  ) async {
    final result = await Process.start('aws', [
      'configure',
      'export-credentials',
      '--profile',
      profile,
    ]).timeout(const Duration(seconds: 30));

    final stdout = await result.stdout.transform(utf8.decoder).join();
    final exitCode = await result.exitCode;
    if (exitCode != 0) {
      throw Exception('AWS profile "$profile" not found or CLI not configured');
    }

    late final Map<String, dynamic> data;
    try {
      data = jsonDecode(stdout) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw Exception('Invalid JSON response from AWS CLI: $e');
    }

    return shared.AwsClientCredentials(
      accessKey: data['AccessKeyId'],
      secretKey: data['SecretAccessKey'],
      sessionToken: data['SessionToken'],
      expiration: data['Expiration'] != null
          ? DateTime.parse(data['Expiration'])
          : null,
    );
  }

  static Future<shared.AwsClientCredentials?> refreshCredentialsIfNeeded(
    shared.AwsClientCredentials? credentials,
  ) async {
    if (credentials == null ||
        (credentials.expiration != null &&
            DateTime.now().isAfter(
              credentials.expiration!.subtract(Duration(seconds: 60)),
            ))) {
      return await getCredentials();
    }
    return null;
  }
}
