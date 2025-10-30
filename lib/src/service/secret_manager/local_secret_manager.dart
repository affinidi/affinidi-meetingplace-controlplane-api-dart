import 'dart:io';

import '../../core/secret_manager/secret_provider.dart';

class LocalSecretManager implements SecretProvider {
  @override
  Future<String> getSecret(String secretId) async {
    return File(secretId).readAsString();
  }
}
