import 'package:meeting_place_control_plane_api/src/api/accept_offer_group/request_model.dart';
import 'package:meeting_place_control_plane_api/src/utils/platform_type.dart';

AcceptOfferGroupRequest getAcceptOfferGroupRequest({
  required String did,
  required String deviceToken,
  required PlatformType platformType,
  String? mnemonic,
}) => AcceptOfferGroupRequest(
  did: did,
  mnemonic: mnemonic ?? 'offer-mnemonic',
  deviceToken: deviceToken,
  platformType: platformType,
  vcard: 'dmNhcmQtdmFsdWUK',
);
