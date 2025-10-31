class SendMessageInput {
  SendMessageInput({
    required this.offerLink,
    required this.groupDid,
    required this.controllingDid,
    required this.messagePayload,
    required this.incSeqNo,
    required this.notify,
  });
  final String offerLink;
  final String groupDid;
  final String controllingDid;
  final bool incSeqNo;
  final String messagePayload;
  final bool notify;
}
