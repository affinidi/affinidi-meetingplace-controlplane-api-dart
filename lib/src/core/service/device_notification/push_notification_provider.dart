abstract interface class PushNotificationProvider {
  Future<String?> createPlatformEndpoint({
    required String platformApplicationArn,
    required String deviceToken,
    String? metadata,
  });

  Future<void> send({
    required String targetArn,
    required String payload,
  });
}
