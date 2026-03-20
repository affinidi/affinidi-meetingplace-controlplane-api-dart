class NotifyGroupMembersInput {
  NotifyGroupMembersInput({
    required this.groupId,
    required this.type,
    required this.controllingDid,
  });

  final String groupId;
  final String type;
  final String controllingDid;
}
