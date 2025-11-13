import 'dart:io';
import 'package:dotenv/dotenv.dart';

String getEnv(String key) {
  final runtimeEnv = String.fromEnvironment('ENV', defaultValue: 'DEV');

  if (runtimeEnv == 'DEV' && File('.env').existsSync()) {
    final env = DotEnv(includePlatformEnvironment: true)..load();
    return _getEnvValue(env, key);
  }
  return _getEnvValue(Platform.environment, key);
}

String? getEnvOrNull(String key) {
  final runtimeEnv = String.fromEnvironment('ENV', defaultValue: 'DEV');

  if (runtimeEnv == 'DEV' && File('.env').existsSync()) {
    final env = DotEnv(includePlatformEnvironment: true)..load();
    return env[key] ?? Platform.environment[key];
  }
  return Platform.environment[key];
}

String _getEnvValue(dynamic env, String key) {
  final envValue = env[key] ?? Platform.environment[key];
  if (envValue == null) {
    throw Exception('Environment variable $key not set');
  }
  return envValue;
}
