import 'dart:convert';

import 'package:api_meetingplace_dart_oss/src/api/register_offer_group/request_model.dart';
import 'package:api_meetingplace_dart_oss/src/core/config/env_config.dart';
import 'package:api_meetingplace_dart_oss/src/utils/platform_type.dart';

import '../utils/did_generator.dart';

Future<RegisterOfferGroupRequest> getRegisterOfferGroupRequestMock({
  required String deviceToken,
  required PlatformType platformType,
  String? validUntil,
  int? maximumUsage,
  String? customPhrase,
}) async {
  return RegisterOfferGroupRequest(
    offerName: 'test offer',
    offerDescription: 'offer used in tests',
    didcommMessage: 'ZGlkY29tbW1lc3NhZ2UK',
    vcard: 'e30K',
    validUntil: validUntil,
    maximumUsage: maximumUsage,
    deviceToken: deviceToken,
    platformType: platformType,
    mediatorDid: getEnv('MEDIATOR_DID'),
    mediatorEndpoint: 'https://mediator.yourdomain.com',
    mediatorWSSEndpoint: 'ws://mediator.yourdomain.com',
    customPhrase: customPhrase,
    adminReencryptionKey:
        'a4f9c12e7b38d6f1c0e5a7b49d8235fa17c2e68b94f1d2c3b6e8f7a1c4d9b0e2',
    adminDid: await DidGenerator.generateDidKey(),
    adminPublicKey: 'qYcKlmOtaVdoj0+KvdX1eaLH16d47EcNlEvAAq4rwm0=',
    memberVCard: 'eyJuIjp7ImdpdmVuIjoiQm9iIiwic3VybmFtZSI6IkEuIn19',
    metadata: jsonEncode({'group': 'meta'}),
  );
}
