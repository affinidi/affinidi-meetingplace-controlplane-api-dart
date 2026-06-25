import 'dart:convert';

import 'package:meeting_place_control_plane_api/src/api/register_offer_group/request_model.dart';
import 'package:meeting_place_control_plane_api/src/core/config/env_config.dart';
import 'package:meeting_place_control_plane_api/src/utils/platform_type.dart';
import 'package:ssi/ssi.dart';

import '../utils/did_generator.dart';

Future<RegisterOfferGroupRequest> getRegisterOfferGroupRequestMock({
  required String deviceToken,
  required PlatformType platformType,
  required Wallet wallet,
  String? validUntil,
  int? maximumUsage,
  String? customPhrase,
}) async {
  return RegisterOfferGroupRequest(
    offerName: 'test offer',
    offerDescription: 'offer used in tests',
    didcommMessage: 'ZGlkY29tbW1lc3NhZ2UK',
    contactCard: 'e30K',
    validUntil: validUntil,
    maximumUsage: maximumUsage,
    deviceToken: deviceToken,
    platformType: platformType,
    mediatorDid: getEnv('MEDIATOR_DID'),
    mediatorEndpoint: 'https://mediator.yourdomain.com',
    mediatorWSSEndpoint: 'ws://mediator.yourdomain.com',
    customPhrase: customPhrase,
    adminDid: await DidGenerator.generateDidKey(wallet),
    memberContactCard: 'eyJuIjp7ImdpdmVuIjoiQm9iIiwic3VybmFtZSI6IkEuIn19',
    metadata: jsonEncode({'group': 'meta'}),
  );
}
