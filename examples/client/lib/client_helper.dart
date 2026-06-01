import 'dart:convert';

import 'package:meeting_place_control_plane_api/meeting_place_control_plane_api.dart';
import 'package:didcomm/didcomm.dart';
import 'package:dio/dio.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

class ClientHelper {
  final String apiEndpoint;
  final String controlPlaneDid;
  late final Dio _dio;

  ClientHelper({required this.apiEndpoint, required this.controlPlaneDid}) {
    _dio = Dio();
  }

  Future<(DidKeyManager, KeyPair)> createDidManagerWithKeyPair() async {
    final wallet = PersistentWallet(InMemoryKeyStore());
    final keyPair = await wallet.generateKey(keyId: "m/44'/60'/0'/0");
    return (
      await createDidManagerFromKeyPair(wallet: wallet, keyPair: keyPair),
      keyPair,
    );
  }

  Future<DidKeyManager> createDidManagerFromKeyPair({
    required Wallet wallet,
    required KeyPair keyPair,
  }) async {
    final didManager = DidKeyManager(wallet: wallet, store: InMemoryDidStore());
    await didManager.addVerificationMethod(keyPair.id);
    return didManager;
  }

  Future<String> authenticate({
    required DidKeyManager didManager,
    required KeyPair keyPair,
    SignatureScheme signatureScheme = SignatureScheme.ecdsa_p256_sha256,
  }) async {
    final challengeResponse = await getChallengeResponse(
      didManager: didManager,
      keyPair: keyPair,
      signatureScheme: signatureScheme,
    );

    final authenticateResponse = await _dio.post(
      '$apiEndpoint/v1/authenticate',
      data: {'challenge_response': challengeResponse},
    );

    return authenticateResponse.data['access_token'];
  }

  Future<String> getMatrixChallengeResponse({
    required DidKeyManager didManager,
    required KeyPair keyPair,
    SignatureScheme signatureScheme = SignatureScheme.ecdsa_p256_sha256,
  }) async {
    return _getChallengeResponseForEndpoint(
      didManager: didManager,
      keyPair: keyPair,
      signatureScheme: signatureScheme,
      challengeEndpoint: '/v1/matrix/challenge',
    );
  }

  Future<String> getChallengeResponse({
    required DidKeyManager didManager,
    required KeyPair keyPair,
    SignatureScheme signatureScheme = SignatureScheme.ecdsa_p256_sha256,
  }) async {
    return _getChallengeResponseForEndpoint(
      didManager: didManager,
      keyPair: keyPair,
      signatureScheme: signatureScheme,
      challengeEndpoint: '/v1/authenticate/challenge',
    );
  }

  Future<String> _getChallengeResponseForEndpoint({
    required DidKeyManager didManager,
    required KeyPair keyPair,
    required SignatureScheme signatureScheme,
    required String challengeEndpoint,
  }) async {
    final didDocument = await didManager.getDidDocument();

    final challengeResponse = await _dio.post(
      '$apiEndpoint$challengeEndpoint',
      data: {'did': didDocument.id},
    );

    final challengeToken = challengeResponse.data['challenge'];

    final plaintextMessage = PlainTextMessage(
      id: const Uuid().v4(),
      type: Uri.parse(
        'https://affinidi.com/didcomm/protocols/meeting-place-control-plane/1.0/authenticate',
      ),
      body: {'challenge': challengeToken},
      to: [controlPlaneDid],
      from: didDocument.id,
      createdTime: DateTime.now().toUtc(),
      expiresTime: DateTime.now().toUtc().add(const Duration(seconds: 60)),
    );

    final resolver = LocalDidResolver();
    final controlPlaneDidDoc = await resolver.resolveDid(controlPlaneDid);
    final didKeyId = didDocument
        .matchKeysInKeyAgreement(otherDidDocuments: [controlPlaneDidDoc])
        .first;

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

    return base64Encode(utf8.encode(json.encode(encrypted)));
  }

  Dio getDio() {
    return Dio(BaseOptions(headers: {'Content-Type': 'application/json'}));
  }

  /// Fetches a long-lived Matrix registration permission JWT from the Control Plane.
  ///
  /// Flow:
  /// - Preferred: reuse a Bearer access token from `/v1/authenticate`.
  /// - Fallback: do a DIDComm challenge+proof (same as authenticate flow).
  Future<String> getMatrixRegistrationCredentialJwt({
    required DidKeyManager didManager,
    required KeyPair keyPair,
    required String homeserver,
    String? accessToken,
    SignatureScheme signatureScheme = SignatureScheme.ecdsa_p256_sha256,
  }) async {
    final didDocument = await didManager.getDidDocument();

    // Preferred path: no extra challenge if we already have a valid token.
    if (accessToken != null && accessToken.isNotEmpty) {
      final dioWithAuth = getDioWithAuth(accessToken);
      final response = await dioWithAuth.post(
        '$apiEndpoint/api/did/matrix-registration-credential',
        data: {'homeserver': homeserver},
      );
      return response.data['credential'] as String;
    }

    final challengeResponse = await _dio.post(
      '$apiEndpoint/v1/authenticate/challenge',
      data: {'did': didDocument.id},
    );
    final challengeToken = challengeResponse.data['challenge'] as String;

    final plaintextMessage = PlainTextMessage(
      id: const Uuid().v4(),
      type: Uri.parse(
        'https://affinidi.com/didcomm/protocols/meeting-place-control-plane/1.0/authenticate',
      ),
      body: {'challenge': challengeToken},
      to: [controlPlaneDid],
      from: didDocument.id,
      createdTime: DateTime.now().toUtc(),
      expiresTime: DateTime.now().toUtc().add(const Duration(seconds: 60)),
    );

    final resolver = LocalDidResolver();
    final controlPlaneDidDoc = await resolver.resolveDid(controlPlaneDid);
    final didKeyId = didDocument
        .matchKeysInKeyAgreement(otherDidDocuments: [controlPlaneDidDoc])
        .first;

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

    final response = await _dio.post(
      '$apiEndpoint/api/did/matrix-registration-credential',
      data: {
        'did': didDocument.id,
        'challenge': challengeToken,
        'signature': signature,
        'homeserver': homeserver,
      },
    );

    return response.data['credential'] as String;
  }

  Dio getDioWithAuth(String accessToken) {
    return Dio(
      BaseOptions(
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      ),
    );
  }
}
