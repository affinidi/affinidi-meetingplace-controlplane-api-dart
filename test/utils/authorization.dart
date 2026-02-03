import 'dart:convert';
import 'dart:typed_data';

import 'package:base_codecs/base_codecs.dart';
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

handleAuthorization(
  DidManager didManager,
  KeyPair keyPair, [
  SignatureScheme signatureScheme = SignatureScheme.ecdsa_p256_sha256,
]) async {
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
      signatureScheme: signatureScheme,
    ),
  );

  final encodedEncrypted = base64Encode(utf8.encode(json.encode(encrypted)));
  Response authenticateResponse = await dioInstance.post(
    '$apiEndpoint/v1/authenticate',
    data: {'challenge_response': encodedEncrypted},
  );

  return authenticateResponse.data['access_token'];
}

Future<(DidManager, KeyPair)> getAdminDidManagerAndKeyPair([
  String keyid = "m/44'/60'/0'/0/0",
]) async {
  // Note: Seed used here for example purposes only.
  // In production, use secure key management.
  final adminSeed =
      'a2fd9c0c6c6f4df0e3b3c8e9f1a4d5e2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8';
  final adminWallet = Bip32Wallet.fromSeed(
    Uint8List.fromList(hex.decode(adminSeed)),
  );

  final adminKeyPair = await adminWallet.generateKey(keyId: keyid);
  final adminDidManager = DidKeyManager(
    wallet: adminWallet,
    store: InMemoryDidStore(),
  );
  await adminDidManager.addVerificationMethod(adminKeyPair.id);

  return (adminDidManager, adminKeyPair);
}
