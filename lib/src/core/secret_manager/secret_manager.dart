import 'secret_provider.dart';

class SecretManager {
  SecretManager._(SecretProvider provider) : _provider = provider {
    _instance = this;
  }

  factory SecretManager.withProvider(SecretProvider provider) {
    return SecretManager._(provider);
  }

  factory SecretManager.get() {
    return _instance ?? (throw Exception('SecretManager not initialized'));
  }

  final SecretProvider _provider;
  static SecretManager? _instance;

  Future<String> getSecret(String secretId) {
    return _provider.getSecret(secretId);
  }
}
