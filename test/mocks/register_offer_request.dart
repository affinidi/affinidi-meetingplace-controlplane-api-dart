import 'package:meeting_place_control_plane_api/src/api/register_offer/request_model.dart';
import 'package:meeting_place_control_plane_api/src/utils/platform_type.dart';

RegisterOfferRequest getRegisterOfferRequestMock({
  required String deviceToken,
  required PlatformType platformType,
  String? validUntil,
  int? maximumUsage,
  String? customPhrase,
}) => RegisterOfferRequest(
  offerName: 'test offer',
  offerDescription: 'offer used in tests',
  didcommMessage: 'ZGlkY29tbW1lc3NhZ2UK',
  vcard: 'e30K',
  validUntil: validUntil,
  maximumUsage: maximumUsage,
  deviceToken: deviceToken,
  platformType: platformType,
  mediatorDid: 'did:local:8080',
  mediatorEndpoint: 'https://mediator.yourdomain.com',
  mediatorWSSEndpoint: 'ws://mediator.yourdomain.com',
  contactAttributes: 1,
  customPhrase: customPhrase,
);
