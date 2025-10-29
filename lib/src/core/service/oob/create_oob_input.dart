class CreateOobInput {
  CreateOobInput({
    required this.mediatorDid,
    required this.mediatorEndpoint,
    required this.mediatorWSSEndpoint,
    required this.didcommMessage,
  });
  final String mediatorDid;
  final String mediatorEndpoint;
  final String mediatorWSSEndpoint;
  final String didcommMessage;
}
