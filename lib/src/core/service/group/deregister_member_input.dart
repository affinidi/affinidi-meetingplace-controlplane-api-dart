class DeregisterMemberInput {
  DeregisterMemberInput({
    required this.groupId,
    required this.controllingDid,
    required this.messageToRelay,
  });

  final String groupId;
  final String controllingDid;
  final String messageToRelay;
}
