import 'dart:convert';

import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_control_plane_api/src/core/service/auth/auth_response.dart';
import 'package:meeting_place_control_plane_api/src/core/service/auth/didcomm_client.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

Future<({DidKeyManager didManager, DidDocument didDocument, DidSigner signer})>
_createIdentity() async {
  final wallet = PersistentWallet(InMemoryKeyStore());
  final didManager = DidKeyManager(wallet: wallet, store: InMemoryDidStore());
  final keyId = (await wallet.generateKey(keyType: KeyType.ed25519)).id;
  final addResult = await didManager.addVerificationMethod(keyId);
  final didDocument = await didManager.getDidDocument();
  final signer = await didManager.getSigner(addResult.verificationMethodId);
  return (didManager: didManager, didDocument: didDocument, signer: signer);
}

Future<String> _buildChallengeResponse({
  required PlainTextMessage message,
  required DidKeyManager didManager,
  required DidDocument senderDidDocument,
  required DidSigner signer,
  required DidDocument recipientDidDocument,
}) async {
  final keyAgreementKeyId = senderDidDocument.keyAgreement.first.id;
  final keyPair = await didManager.getKeyPairByDidKeyId(keyAgreementKeyId);
  final encryptedMessage =
      await DidcommMessage.packIntoSignedAndEncryptedMessages(
        message,
        keyPair: keyPair,
        didKeyId: keyAgreementKeyId,
        recipientDidDocuments: [recipientDidDocument],
        keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdh1Pu,
        encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
        signer: signer,
      );
  return base64Url.encode(utf8.encode(jsonEncode(encryptedMessage.toJson())));
}

void main() {
  group('AuthClient.unpackChallengeResponse', () {
    test('returns didcommChallengeOk on a valid signed message', () async {
      final recipient = await _createIdentity();
      final sender = await _createIdentity();
      final client = AuthClient(
        privateJwks: const [],
        recipientDidManager: recipient.didManager,
      );

      final response = await client.unpackChallengeResponse(
        await _buildChallengeResponse(
          message: PlainTextMessage(
            id: 'challenge-1',
            type: Uri.parse('https://affinidi.com/atm/1.0/authenticate'),
            from: sender.didDocument.id,
            to: [recipient.didDocument.id],
            expiresTime: DateTime.now().toUtc().add(const Duration(minutes: 1)),
            body: {'challenge': 'signed-challenge'},
          ),
          didManager: sender.didManager,
          senderDidDocument: sender.didDocument,
          signer: sender.signer,
          recipientDidDocument: recipient.didDocument,
        ),
      );

      expect(response.type, AuthenticationResponseType.didcommChallengeOk);
      expect(response.did, sender.didDocument.id);
      expect(response.challenge, 'signed-challenge');
    });

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
            didManager: signerIdentity.didManager,
            senderDidDocument: signerIdentity.didDocument,
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
