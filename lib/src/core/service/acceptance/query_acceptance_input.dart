class QueryAcceptanceInput {
  QueryAcceptanceInput({
    required this.mnemonic,
    required this.didUsedForAcceptance,
    required this.offerLink,
  });
  final String mnemonic;
  final String didUsedForAcceptance;
  final String offerLink;
}
