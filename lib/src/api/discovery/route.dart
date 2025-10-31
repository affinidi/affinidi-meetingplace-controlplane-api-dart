import 'dart:convert';

import '../../core/config/config.dart';
import '../../core/config/env_config.dart';
import '../../core/service/auth/didcomm_auth.dart';
import 'package:didcomm/didcomm.dart';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';

import '../../core/service/auth/didcomm_auth_builder.dart';
import '../application_facade.dart';

Future<Response> discoverApi(Request request, ApplicationFacade facade) async {
  final DIDCommAuth didcommauth =
      await DIDCommAuthBuilder(logger: facade.config.logger).build();
  final config = Config().get('auth');

  final plainTextmessage = PlainTextMessage(
    id: const Uuid().v4(),
    type: Uri.parse(config['meetingPlaceRegistrationDidcommType']),
    body: {
      'httpApi': getEnv('API_ENDPOINT'),
      'httpApiVersion': 'v1',
    },
    from: getEnv('CONTROL_PLANE_DID'),
    createdTime: DateTime.now(),
    expiresTime: DateTime.now().add(
      Duration(minutes: config['meetingPlaceRegistrationTokenExpiryInMinutes']),
    ),
  );

  final token = didcommauth.getApiDiscoveryToken(
    issuer: getEnv('CONTROL_PLANE_DID'),
    data: plainTextmessage.toJson(),
    expiresInMinutes: config['meetingPlaceRegistrationTokenExpiryInMinutes'],
  );

  return Response.ok(JsonEncoder().convert({'token': token}));
}
