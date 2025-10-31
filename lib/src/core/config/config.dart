import 'dart:io';
import 'package:yaml/yaml.dart';

class Config {
  factory Config() {
    return _config;
  }

  Config._();

  static final Config _config = Config._();
  final Map<String, dynamic> _secrets = {};

  dynamic _envConfig;

  loadConfig(String env) async {
    String fileContent = await File(
      './config.yml',
    ).readAsString();
    _envConfig = loadYaml(fileContent);
    return this;
  }

  dynamic get(String rootKey) {
    if (_envConfig == null) {
      throw Exception('Config not loaded');
    }

    if (_envConfig[rootKey] == null) {
      throw Exception('Config for root key $rootKey not found');
    }

    return _envConfig[rootKey]!;
  }

  void registerSecret(String key, dynamic value) {
    _secrets[key] = value;
  }

  dynamic getSecret(String key) {
    return _secrets[key];
  }

  String hashSecret() {
    return _secrets['hashSecret']['secret'];
  }
}
