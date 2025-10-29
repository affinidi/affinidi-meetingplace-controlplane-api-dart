import 'aws_secret_manager.dart';
import 'local_secret_manager.dart';

abstract interface class ISecretProvider {
  Future<String> getSecret(String secretId);
}

class SecretManager {
  SecretManager._(ISecretProvider provider) {
    _provider = provider;
    _instance = this;
  }

  factory SecretManager.withProvider(ISecretProvider provider) {
    return SecretManager._(provider);
  }

  factory SecretManager.get() {
    if (_instance == null) {
      return SecretManager.withProvider(LocalSecretManager());
    }
    return _instance!;
  }
  static SecretManager? _instance;
  late ISecretProvider _provider;

  static Future<SecretManager> init(String secretManager) async {
    switch (secretManager) {
      case 'local':
        return SecretManager.withProvider(LocalSecretManager());
      case 'aws':
        return SecretManager.withProvider(await AWSSecretManager.init());
      default:
        throw Exception('Configured secret manager not supported');
    }
  }

  Future<String> getSecret(String secretId) {
    return _provider.getSecret(secretId);
  }
}
