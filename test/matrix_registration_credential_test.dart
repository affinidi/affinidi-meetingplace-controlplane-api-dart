import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:didcomm/didcomm.dart';
import 'package:dio/dio.dart';
import 'package:meeting_place_control_plane_api/meeting_place_control_plane_api.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import 'utils/authorization.dart' show buildPlaintextMessage;

void main() {
  final apiEndpoint = getEnv('API_ENDPOINT');
  final dio = Dio();

  final runIntegrationTests =
      (getEnvOrNull('RUN_INTEGRATION_TESTS') ?? '').toLowerCase() == 'true';

  test('matrix-registration-credential: issues verifiable JWT', () async {
    final wallet = PersistentWallet(InMemoryKeyStore());
    final keyPair = await wallet.generateKey(keyId: "m/44'/60'/0'/0");

    final didManager = DidKeyManager(wallet: wallet, store: InMemoryDidStore());
    await didManager.addVerificationMethod(keyPair.id);
    final didDocument = await didManager.getDidDocument();

    final challengeResponse = await dio.post(
      '$apiEndpoint/v1/authenticate/challenge',
      data: {'did': didDocument.id},
    );

    final challengeToken = challengeResponse.data['challenge'] as String;

    final plaintextMessage = buildPlaintextMessage(
      challengeToken: challengeToken,
      did: didDocument.id,
    );

    final DidDocument controlPlaneDidDoc = await LocalDidResolver().resolveDid(
      getEnv('CONTROL_PLANE_DID'),
    );

    final didKeyId = didDocument
        .matchKeysInKeyAgreement(otherDidDocuments: [controlPlaneDidDoc])
        .first;

    final signatureScheme =
        keyPair.supportedSignatureSchemes.contains(
          SignatureScheme.ecdsa_secp256k1_sha256,
        )
        ? SignatureScheme.ecdsa_secp256k1_sha256
        : SignatureScheme.ecdsa_p256_sha256;

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
        signatureScheme: signatureScheme,
      ),
    );

    final signature = base64Encode(utf8.encode(json.encode(encrypted)));

    // Authenticate once and reuse access token (preferred path).
    final authenticateResponse = await dio.post(
      '$apiEndpoint/v1/authenticate',
      data: {'challenge_response': signature},
    );

    final accessToken = authenticateResponse.data['access_token'] as String;

    final response = await dio.post(
      '$apiEndpoint/api/did/matrix-registration-credential',
      data: {'homeserver': 'matrix.example.com'},
      options: Options(
        headers: {
          Headers.contentTypeHeader: 'application/json',
          'authorization': 'Bearer $accessToken',
        },
      ),
    );

    expect(response.data['did'], equals(didDocument.id));
    expect(response.data['credential'], isA<String>());

    final credential = response.data['credential'] as String;

    final didDocResponse = await dio.get('$apiEndpoint/.well-known/did.json');
    final didDocJson = Map<String, dynamic>.from(didDocResponse.data as Map);

    final decoded = JWT.decode(credential);
    final kid = decoded.header?['kid'] as String?;
    expect(kid, isNotNull, reason: 'JWT must include kid for key selection');

    final verificationMethods = (didDocJson['verificationMethod'] as List?)
        ?.map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    expect(
      verificationMethods,
      isNotNull,
      reason: 'DID document must include verificationMethod',
    );

    final verificationMethod = verificationMethods!.firstWhere(
      (vm) => vm['id'] == kid,
    );

    final publicJwk = verificationMethod['publicKeyJwk'] as Map?;
    expect(publicJwk, isNotNull, reason: 'verificationMethod must have JWK');

    final publicKey = JWTKey.fromJWK(Map<String, dynamic>.from(publicJwk!));
    final jwt = JWT.verify(credential, publicKey);

    expect(jwt.payload['sub'], equals(didDocument.id));
    expect(jwt.payload['iss'], equals(getEnv('CONTROL_PLANE_DID')));
    expect(jwt.payload['scope'], equals('matrix.register'));

    final aud = jwt.payload['aud'];
    if (aud is String) {
      expect(aud, equals('https://matrix.example.com'));
    } else if (aud is List) {
      expect(aud, contains('https://matrix.example.com'));
    } else {
      fail('Unexpected aud claim type: ${aud.runtimeType}');
    }
  });
}
