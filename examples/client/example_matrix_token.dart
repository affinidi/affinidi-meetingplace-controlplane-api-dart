import 'dart:io';

import 'package:dotenv/dotenv.dart';

import 'lib/client_helper.dart';

Future<void> main() async {
  final env = DotEnv()..load(['.env']);

  final apiEndpoint = env['API_ENDPOINT'] ?? 'http://localhost:3000';
  final controlPlaneDid = env['CONTROL_PLANE_DID'] ?? 'did:localhost:3000';

  print('=== Client Example - Matrix Token Issuance ===\n');

  final helper = ClientHelper(
    apiEndpoint: apiEndpoint,
    controlPlaneDid: controlPlaneDid,
  );

  print('1. Creating Alice\'s DID...');
  final (aliceDidManager, aliceKeyPair) =
      await helper.createDidManagerWithKeyPair();

  final aliceDidDoc = await aliceDidManager.getDidDocument();
  final aliceChallengeResponse = await helper.getChallengeResponse(
    didManager: aliceDidManager,
    keyPair: aliceKeyPair,
  );

  print('   Alice DID: ${aliceDidDoc.id}');
  print('   Alice Challenge Response: $aliceChallengeResponse\n');

  print('2. Alice requests matrix token for her DID...');
  final tokenResponse = await helper.getDio().post(
    '$apiEndpoint/v1/matrix/token',
    data: {
      'homeserver': 'https://matrix.org',
      'challenge_response': aliceChallengeResponse,
    },
  );
  print('   Matrix Login Token: ${tokenResponse.data['token']}\n');
  exit(0);
}
