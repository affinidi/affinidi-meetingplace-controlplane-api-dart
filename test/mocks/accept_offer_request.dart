import 'package:meeting_place_control_plane_api/src/api/accept_offer/request_model.dart';
import 'package:meeting_place_control_plane_api/src/utils/platform_type.dart';

AcceptOfferRequest getAcceptOfferRequest({
  required String did,
  required String deviceToken,
  required PlatformType platformType,
  String? mnemonic,
}) => AcceptOfferRequest(
  did: did,
  mnemonic: mnemonic ?? 'offer-mnemonic',
  deviceToken: deviceToken,
  platformType: platformType,
  vcard: 'dmNhcmQtdmFsdWUK',
);
