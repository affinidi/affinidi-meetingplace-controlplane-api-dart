import '../../../utils/platform_type.dart';

class FinaliseAcceptanceInput {
  FinaliseAcceptanceInput({
    required this.mnemonic,
    required this.offerLink,
    required this.didUsedForAcceptance,
    required this.theirDid,
    this.deviceToken,
    this.platformType,
  });
  final String mnemonic;
  final String offerLink;
  final String didUsedForAcceptance;
  final String theirDid;
  final String? deviceToken;
  final PlatformType? platformType;
}
