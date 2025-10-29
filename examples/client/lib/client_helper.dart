import 'dart:convert';

// ignore: implementation_imports
import 'package:api_meetingplace_dart_oss/src/core/did_resolver/did_local_resolver.dart';
import 'package:didcomm/didcomm.dart';
import 'package:dio/dio.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

class ClientHelper {
  final String apiEndpoint;
  final String controlPlaneDid;
  late final Dio _dio;

  ClientHelper({
    required this.apiEndpoint,
    required this.controlPlaneDid,
  }) {
    _dio = Dio();
  }

  Future<(DidKeyManager, KeyPair)> createDidManagerWithKeyPair() async {
    final wallet = PersistentWallet(InMemoryKeyStore());
    final keyPair = await wallet.generateKey(keyId: "m/44'/60'/0'/0");
    final didManager = DidKeyManager(wallet: wallet, store: InMemoryDidStore());
    await didManager.addVerificationMethod(keyPair.id);
    return (didManager, keyPair);
  }

  Future<String> authenticate(DidKeyManager didManager, KeyPair keyPair) async {
    final didDocument = await didManager.getDidDocument();

    final challengeResponse = await _dio.post(
      '$apiEndpoint/v1/authenticate/challenge',
      data: {'did': didDocument.id},
    );

    final challengeToken = challengeResponse.data['challenge'];

    final plaintextMessage = PlainTextMessage(
      id: const Uuid().v4(),
      type: Uri.parse('https://affinidi.io/mpx/control-plane/authenticate'),
      body: {'challenge': challengeToken},
      to: [controlPlaneDid],
      from: didDocument.id,
      createdTime: DateTime.now().toUtc(),
      expiresTime: DateTime.now().toUtc().add(const Duration(seconds: 60)),
    );

    final resolver = LocalDidResolver();
    final controlPlaneDidDoc = await resolver.resolveDid(controlPlaneDid);
    final didKeyId = didDocument.matchKeysInKeyAgreement(
      otherDidDocuments: [controlPlaneDidDoc],
    ).first;

    final encrypted = await DidcommMessage.packIntoSignedAndEncryptedMessages(
      plaintextMessage,
      didKeyId: didKeyId,
      keyPair: keyPair,
      recipientDidDocuments: [controlPlaneDidDoc],
      keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdh1Pu,
      encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
      signer: DidSigner(
        did: didDocument.id,
        didKeyId: didKeyId,
        keyPair: keyPair,
        signatureScheme: SignatureScheme.ecdsa_p256_sha256,
      ),
    );

    final encodedEncrypted = base64Encode(utf8.encode(json.encode(encrypted)));
    final authenticateResponse = await _dio.post(
      '$apiEndpoint/v1/authenticate',
      data: {'challenge_response': encodedEncrypted},
    );

    return authenticateResponse.data['access_token'];
  }

  Dio getDioWithAuth(String accessToken) {
    return Dio(BaseOptions(
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    ));
  }
}
