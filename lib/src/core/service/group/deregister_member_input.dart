class DeregisterMemberInput {
  DeregisterMemberInput({
    required this.groupId,
    required this.memberDid,
    required this.controllingDid,
  });

  final String groupId;
  final String memberDid;
  final String controllingDid;
}
