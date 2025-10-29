import '../../../utils/platform_type.dart';

class AcceptOfferInput {
  AcceptOfferInput({
    required this.acceptOfferAsDid,
    required this.mnemonic,
    required this.deviceToken,
    required this.platformType,
    required this.vcard,
  });
  final String acceptOfferAsDid;
  final String mnemonic;
  final String deviceToken;
  final PlatformType platformType;
  final String vcard;
}
