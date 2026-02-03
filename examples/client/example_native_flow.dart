import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart';

import 'lib/client_helper.dart';

String generateContactCard(String fullName) {
  final card = jsonEncode({
    'firstName': fullName.split(' ').first,
    'lastName': fullName.split(' ').length > 1
        ? fullName.split(' ').sublist(1).join(' ')
        : ''
  });
  return base64Encode(utf8.encode(card));
}

String generateDidcommInvitation(String did, String endpoint) {
  final invitation = {
    'type': 'https://didcomm.org/out-of-band/2.0/invitation',
    'id': 'invitation-id',
    'from': did,
    'body': {
      'goal_code': 'connect',
      'goal': 'Establish connection',
      'accept': ['didcomm/v2'],
    },
    'services': [
      {'serviceEndpoint': endpoint},
    ],
  };
  return base64Encode(utf8.encode(jsonEncode(invitation)));
}

Future<void> main() async {
  final env = DotEnv()..load(['.env', '.env']);

  final apiEndpoint = env['API_ENDPOINT'] ?? 'http://localhost:3000';
  final controlPlaneDid = env['CONTROL_PLANE_DID'] ?? 'did:localhost:3000';

  print('=== Client Example ===\n');

  final helper = ClientHelper(
    apiEndpoint: apiEndpoint,
    controlPlaneDid: controlPlaneDid,
  );

  print('1. Creating Alice\'s DID and authenticating...');
  final (aliceDidManager, aliceKeyPair) =
      await helper.createDidManagerWithKeyPair();
  final aliceDidDoc = await aliceDidManager.getDidDocument();
  final aliceToken = await helper.authenticate(
      didManager: aliceDidManager, keyPair: aliceKeyPair);

  print('   Alice DID: ${aliceDidDoc.id}');
  print('   Alice authenticated\n');

  print('2. Alice registers her device...');
  final aliceDio = helper.getDioWithAuth(aliceToken);
  await aliceDio.post(
    '$apiEndpoint/v1/register-device',
    data: {
      'deviceToken': 'example-device-token-alice',
      'platformType': 'PUSH_NOTIFICATION',
    },
  );
  print('   Device registered\n');

  print('3. Alice registers a connection offer...');
  final registerResponse = await aliceDio.post(
    '$apiEndpoint/v1/register-offer',
    data: {
      'offerName': 'Alice\'s Connection',
      'offerDescription': 'Connect with Alice',
      'didcommMessage': generateDidcommInvitation(
        aliceDidDoc.id,
        'https://mediator.yourdomain.com',
      ),
      'contactCard': generateContactCard('Alice Example'),
      'deviceToken': 'example-device-token-alice',
      'platformType': 'PUSH_NOTIFICATION',
      'mediatorDid': 'did:web:mediator',
      'mediatorEndpoint': 'https://mediator.yourdomain.com',
      'mediatorWSSEndpoint': 'ws://mediator.yourdomain.com',
      'contactAttributes': 1,
    },
  );
  final mnemonic = registerResponse.data['mnemonic'];
  print('   Offer registered');
  print('   Mnemonic: $mnemonic');
  print('   Offer Link: ${registerResponse.data['offerLink']}\n');

  print('4. Creating Bob\'s DID and authenticating...');
  final (bobDidManager, bobKeyPair) =
      await helper.createDidManagerWithKeyPair();
  final bobDidDoc = await bobDidManager.getDidDocument();
  final bobToken =
      await helper.authenticate(didManager: bobDidManager, keyPair: bobKeyPair);
  print('   Bob DID: ${bobDidDoc.id}');
  print('   Bob authenticated\n');

  print('5. Bob registers his device...');
  final bobDio = helper.getDioWithAuth(bobToken);
  await bobDio.post(
    '$apiEndpoint/v1/register-device',
    data: {
      'deviceToken': 'example-device-token-bob',
      'platformType': 'PUSH_NOTIFICATION',
    },
  );
  print('   Device registered\n');

  print('6. Bob queries the offer...');
  final queryResponse = await bobDio.post(
    '$apiEndpoint/v1/query-offer',
    data: {'mnemonic': mnemonic},
  );
  print('   Offer found: ${queryResponse.data['name']}\n');

  print('7. Bob accepts the offer...');
  final acceptResponse = await bobDio.post(
    '$apiEndpoint/v1/accept-offer',
    data: {
      'did': bobDidDoc.id,
      'mnemonic': mnemonic,
      'deviceToken': 'example-device-token-bob',
      'platformType': 'PUSH_NOTIFICATION',
      'contactCard': generateContactCard('Bob Example'),
    },
  );
  print('   Offer Link: ${acceptResponse.data['offerLink']}');
  print('   DIDComm Message: ${acceptResponse.data['didcommMessage']}\n');

  print('8. Alice finalizes the connection...');
  final finalizeResponse = await aliceDio.post(
    '$apiEndpoint/v1/finalise-acceptance',
    data: {
      'did': bobDidDoc.id,
      'theirDid': aliceDidDoc.id,
      'mnemonic': mnemonic,
      'offerLink': registerResponse.data['offerLink'],
      'deviceToken': 'example-device-token-alice',
      'platformType': 'PUSH_NOTIFICATION',
    },
  );
  print('   Connection finalized');
  print(
    '   Notification Token: ${finalizeResponse.data['notificationToken']}\n',
  );

  print('Complete. Alice and Bob are now connected.\n');

  exit(0);
}
