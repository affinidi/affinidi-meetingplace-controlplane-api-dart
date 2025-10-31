class NotifyChannelInput {
  NotifyChannelInput({
    required this.notificationChannelId,
    required this.did,
    required this.type,
  });
  final String notificationChannelId;
  final String did;
  final String type;
}
