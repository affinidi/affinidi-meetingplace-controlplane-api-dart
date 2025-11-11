import 'dart:convert';

import 'package:meeting_place_control_plane_api/meeting_place_control_plane_api.dart';

import 'package:didcomm/didcomm.dart';
import 'package:dio/dio.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

final apiEndpoint = getEnv('API_ENDPOINT');

PlainTextMessage buildPlaintextMessage({
  required String challengeToken,
  required String did,
}) {
  final DateTime createdTime = DateTime.now().toUtc();
  final DateTime expiresTime = createdTime.add(const Duration(seconds: 60));

  return PlainTextMessage(
    id: const Uuid().v4(),
    type: Uri.parse(
      'https://affinidi.com/didcomm/protocols/mpx/1.0/authenticate',
    ),
    body: {'challenge': challengeToken},
    to: [getEnv('CONTROL_PLANE_DID')],
    from: did,
    createdTime: createdTime,
    expiresTime: expiresTime,
  );
}

handleAuthorization(DidManager didManager, KeyPair keyPair) async {
  final dioInstance = Dio();
  final didDocument = await didManager.getDidDocument();

  Response response = await dioInstance.post(
    '$apiEndpoint/v1/authenticate/challenge',
    data: {'did': didDocument.id},
  );

  final challengeResponse = response.data;

  final plaintextMessage = buildPlaintextMessage(
    challengeToken: challengeResponse['challenge'],
    did: didDocument.id,
  );

  final DidDocument meetingplaceDidDoc = await LocalDidResolver().resolveDid(
    getEnv('CONTROL_PLANE_DID'),
  );

  final senderDidDoc = await didManager.getDidDocument();
  final didKeyId = didDocument
      .matchKeysInKeyAgreement(otherDidDocuments: [meetingplaceDidDoc])
      .first;

  final encrypted = await DidcommMessage.packIntoSignedAndEncryptedMessages(
    plaintextMessage,
    didKeyId: didKeyId,
    keyPair: keyPair,
    recipientDidDocuments: [meetingplaceDidDoc],
    keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdh1Pu,
    encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
    signer: DidSigner(
      did: senderDidDoc.id,
      didKeyId: didKeyId,
      keyPair: keyPair,
      signatureScheme: SignatureScheme.ecdsa_p256_sha256,
    ),
  );

  final encodedEncrypted = base64Encode(utf8.encode(json.encode(encrypted)));
  Response authenticateResponse = await dioInstance.post(
    '$apiEndpoint/v1/authenticate',
    data: {'challenge_response': encodedEncrypted},
  );

  return authenticateResponse.data['access_token'];
}
