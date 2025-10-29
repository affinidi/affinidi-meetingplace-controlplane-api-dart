import 'dart:io';

import 'secret_manager.dart';

class LocalSecretManager implements ISecretProvider {
  @override
  Future<String> getSecret(String secretId) async {
    return File(secretId).readAsString();
  }
}
