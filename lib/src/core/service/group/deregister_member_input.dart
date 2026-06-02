class DeregisterMemberInput {
  DeregisterMemberInput({
    required this.groupId,
    required this.memberDid,
    required this.controllingDid,
    required this.messageToRelay,
  });

  final String groupId;
  final String memberDid;
  final String controllingDid;
  final String messageToRelay;
}
