import 'dart:convert';

import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_control_plane_api/src/core/service/auth/auth_response.dart';
import 'package:meeting_place_control_plane_api/src/core/service/auth/didcomm_client.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

Future<
  ({
    DidKeyManager didManager,
    DidDocument didDocument,
    DidKeyPair didKeyPair,
    DidSigner signer,
  })
>
_createIdentity() async {
  final wallet = PersistentWallet(InMemoryKeyStore());
  final didManager = DidKeyManager(wallet: wallet, store: InMemoryDidStore());
  final keyId = (await wallet.generateKey(keyType: KeyType.ed25519)).id;
  final addResult = await didManager.addVerificationMethod(keyId);
  final didDocument = await didManager.getDidDocument();
  final didKeyPair = await didManager.getKey(addResult.verificationMethodId);
  final signer = await didManager.getSigner(addResult.verificationMethodId);
  return (
    didManager: didManager,
    didDocument: didDocument,
    didKeyPair: didKeyPair,
    signer: signer,
  );
}

Future<String> _buildChallengeResponse({
  required PlainTextMessage message,
  required DidKeyPair didKeyPair,
  required DidSigner signer,
  required DidDocument recipientDidDocument,
}) async {
  final encryptedMessage =
      await DidcommMessage.packIntoSignedAndEncryptedMessages(
        message,
        keyPair: didKeyPair.keyPair,
        didKeyId: didKeyPair.verificationMethodId,
        recipientDidDocuments: [recipientDidDocument],
        keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdh1Pu,
        encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
        signer: signer,
      );
  return base64Url.encode(utf8.encode(jsonEncode(encryptedMessage.toJson())));
}

void main() {
  group('AuthClient.unpackChallengeResponse', () {
    test(
      'returns invalid when the signer DID does not match message.from',
      () async {
        final recipient = await _createIdentity();
        final signerIdentity = await _createIdentity();
        final claimedSender = await _createIdentity();
        final client = AuthClient(
          privateJwks: const [],
          recipientDidManager: recipient.didManager,
        );

        final response = await client.unpackChallengeResponse(
          await _buildChallengeResponse(
            message: PlainTextMessage(
              id: 'challenge-1',
              type: Uri.parse('https://affinidi.com/atm/1.0/authenticate'),
              from: claimedSender.didDocument.id,
              to: [recipient.didDocument.id],
              expiresTime: DateTime.now().toUtc().add(
                const Duration(minutes: 1),
              ),
              body: {'challenge': 'signed-challenge'},
            ),
            didKeyPair: signerIdentity.didKeyPair,
            signer: signerIdentity.signer,
            recipientDidDocument: recipient.didDocument,
          ),
        );

        expect(
          response.type,
          AuthenticationResponseType.invalidChallengeResponse,
        );
      },
    );
  });
}
