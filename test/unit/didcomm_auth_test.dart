import 'dart:convert';

import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_control_plane_api/meeting_place_control_plane_api.dart';
import 'package:meeting_place_control_plane_api/src/core/entity/consumed_challenge.dart';
import 'package:meeting_place_control_plane_api/src/core/entity/entity.dart';
import 'package:meeting_place_control_plane_api/src/core/logger/logger.dart';
import 'package:meeting_place_control_plane_api/src/core/secret_manager/secret_provider.dart';
import 'package:meeting_place_control_plane_api/src/core/service/auth/auth_response.dart';
import 'package:meeting_place_control_plane_api/src/core/service/auth/challenge_purpose.dart';
import 'package:meeting_place_control_plane_api/src/core/service/auth/didcomm_auth_builder.dart';
import 'package:meeting_place_control_plane_api/src/core/service/auth/didcomm_auth_challenge.dart';
import 'package:meeting_place_control_plane_api/src/core/storage/exception/already_exists_exception.dart';
import 'package:meeting_place_control_plane_api/src/core/storage/storage.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

class _NoopLogger implements Logger {
  @override
  void debug(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void info(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void warn(String message, {Object? error, StackTrace? stackTrace}) {}
}

class _FakeSecretProvider implements SecretProvider {
  @override
  Future<String> getSecret(String secretId) {
    return LocalSecretManager().getSecret(secretId);
  }
}

class _ConsumedChallengeStorage implements Storage {
  final Set<String> _consumed = <String>{};

  @override
  Future<Storage> connect() async => this;

  @override
  Future<T> create<T extends Entity>(T object) async {
    if (object is ConsumedChallenge && !_consumed.add(object.jti)) {
      throw AlreadyExists();
    }
    return object;
  }

  @override
  Future<T> add<T extends Entity>(String listName, T object) =>
      throw UnimplementedError();

  @override
  Future<int> count(String entityName) => throw UnimplementedError();

  @override
  Future<void> delete(String entityName, String id) =>
      throw UnimplementedError();

  @override
  Future<void> deleteFromlist(
    String listName,
    String listId,
    String entityName,
    String id,
  ) => throw UnimplementedError();

  @override
  Future<List<T>> findAllById<T>(
    String entityName,
    String id,
    EntityFromJson<T> fromJson,
  ) => throw UnimplementedError();

  @override
  Future<T?> findOneById<T extends Entity>(
    String entityName,
    String id,
    EntityFromJson<T> fromJson,
  ) => throw UnimplementedError();

  @override
  Future<T> update<T extends Entity>(T object) => throw UnimplementedError();

  @override
  Future<T?> updateWithCondition<T extends Entity>(
    String entityName,
    String id,
    EntityFromJson<T> fromJson, {
    required T Function(T entity) updateFn,
    required bool Function(T entity) conditionFn,
  }) => throw UnimplementedError();
}

PlainTextMessage _buildPlaintextMessage({
  required String challengeToken,
  required String did,
}) {
  final createdTime = DateTime.now().toUtc();
  final expiresTime = createdTime.add(const Duration(seconds: 60));

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

Future<String> _buildChallengeResponse({
  required DidManager didManager,
  required KeyPair keyPair,
  required String challengeToken,
}) async {
  final didDocument = await didManager.getDidDocument();
  final controlPlaneDidDoc = await LocalDidResolver().resolveDid(
    getEnv('CONTROL_PLANE_DID'),
  );

  final didKeyId = didDocument
      .matchKeysInKeyAgreement(otherDidDocuments: [controlPlaneDidDoc])
      .first;

  final encrypted = await DidcommMessage.packIntoSignedAndEncryptedMessages(
    _buildPlaintextMessage(challengeToken: challengeToken, did: didDocument.id),
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

  return base64Encode(utf8.encode(jsonEncode(encrypted)));
}

void main() {
  late _ConsumedChallengeStorage storage;
  late DidKeyManager didManager;
  late KeyPair keyPair;
  late SecretManager secretManager;

  setUpAll(() async {
    await Config().loadConfig(getEnv('ENV'));
    secretManager = SecretManager.withProvider(_FakeSecretProvider());
    final config = Config();
    config.registerSecret(
      'didcommauth',
      jsonDecode(await secretManager.getSecret(getEnv('DIDCOMM_AUTH_SECRET'))),
    );
    config.registerSecret(
      'hashSecret',
      jsonDecode(await secretManager.getSecret(getEnv('HASH_SECRET'))),
    );
    config.registerSecret(
      'matrixMediaSigningSecret',
      await secretManager.getSecret(getEnv('MATRIX_MEDIA_SIGNING_SECRET')),
    );
  });

  setUp(() async {
    storage = _ConsumedChallengeStorage();
    final wallet = PersistentWallet(InMemoryKeyStore());
    keyPair = await wallet.generateKey(keyId: "m/44'/60'/0'/0");
    didManager = DidKeyManager(wallet: wallet, store: InMemoryDidStore());
    await didManager.addVerificationMethod(keyPair.id);
  });

  test('invalid matrix challenge response fails fast', () async {
    final auth = await DIDCommAuthBuilder(
      logger: _NoopLogger(),
      storage: storage,
    ).build();

    await expectLater(
      () => auth.authenticateChallengeResponse(
        challengeResponse: 'invalid-challenge',
        didResolverUrl: Config().get('auth')['didResolverUrl'],
        purpose: ChallengePurpose.matrixToken,
      ),
      throwsA(
        isA<ChallengeAuthException>().having(
          (error) => error.reason,
          'reason',
          AuthenticationResponseType.invalidChallengeResponse.name,
        ),
      ),
    );
  });

  test(
    'matrix challenge response is accepted once and rejected on replay',
    () async {
      final auth = await DIDCommAuthBuilder(
        logger: _NoopLogger(),
        storage: storage,
      ).build();
      final didDocument = await didManager.getDidDocument();
      final challengeToken = await DIDCommAuthChallenge.generateAuthChallenge(
        did: didDocument.id,
        secretManager: secretManager,
        purpose: ChallengePurpose.matrixToken,
      );
      final challengeResponse = await _buildChallengeResponse(
        didManager: didManager,
        keyPair: keyPair,
        challengeToken: challengeToken,
      );

      final firstResult = await auth.authenticateChallengeResponse(
        challengeResponse: challengeResponse,
        didResolverUrl: Config().get('auth')['didResolverUrl'],
        purpose: ChallengePurpose.matrixToken,
      );

      expect(firstResult, didDocument.id);

      await expectLater(
        () => auth.authenticateChallengeResponse(
          challengeResponse: challengeResponse,
          didResolverUrl: Config().get('auth')['didResolverUrl'],
          purpose: ChallengePurpose.matrixToken,
        ),
        throwsA(
          isA<ChallengeAuthException>().having(
            (error) => error.reason,
            'reason',
            'challengeAlreadyUsed',
          ),
        ),
      );
    },
  );
}
