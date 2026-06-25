class NotifyChannelInput {
  NotifyChannelInput({
    required this.notificationChannelId,
    required this.did,
    required this.type,
    this.mediaType,
  });
  final String notificationChannelId;
  final String did;
  final String type;
  final String? mediaType;
}
