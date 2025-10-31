abstract interface class SecretProvider {
  Future<String> getSecret(String secretId);
}
