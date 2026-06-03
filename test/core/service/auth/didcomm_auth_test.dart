import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:meeting_place_control_plane_api/src/core/entity/consumed_challenge.dart';
import 'package:meeting_place_control_plane_api/src/core/entity/entity.dart';
import 'package:meeting_place_control_plane_api/src/core/logger/logger.dart';
import 'package:meeting_place_control_plane_api/src/core/service/auth/auth_response.dart';
import 'package:meeting_place_control_plane_api/src/core/service/auth/challenge_purpose.dart';
import 'package:meeting_place_control_plane_api/src/core/service/auth/didcomm_auth.dart';
import 'package:meeting_place_control_plane_api/src/core/storage/exception/already_exists_exception.dart';
import 'package:meeting_place_control_plane_api/src/core/storage/storage.dart';
import 'package:test/test.dart';

class _NoOpLogger implements Logger {
  @override
  void debug(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void info(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void warn(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {}
}

class _InMemoryStorage implements Storage {
  final _data = <String, Map<String, Map<String, dynamic>>>{};

  @override
  Future<Storage> connect() async => this;

  @override
  Future<T> create<T extends Entity>(T object) async {
    final entityName = object.getEntityName();
    final id = object.getId();
    _data.putIfAbsent(entityName, () => {});
    if (_data[entityName]!.containsKey(id)) {
      throw AlreadyExists();
    }
    _data[entityName]![id] = object.toJson();
    return object;
  }

  @override
  Future<T> update<T extends Entity>(T object) async => object;

  @override
  Future<T?> updateWithCondition<T extends Entity>(
    String entityName,
    String id,
    EntityFromJson<T> fromJson, {
    required T Function(T entity) updateFn,
    required bool Function(T entity) conditionFn,
  }) async => null;

  @override
  Future<T> add<T extends Entity>(String listName, T object) async => object;

  @override
  Future<void> delete(String entityName, String id) async {}

  @override
  Future<T?> findOneById<T extends Entity>(
    String entityName,
    String id,
    EntityFromJson<T> fromJson,
  ) async {
    final record = _data[entityName]?[id];
    return record == null ? null : fromJson(record);
  }

  @override
  Future<List<T>> findAllById<T>(
    String entityName,
    String id,
    EntityFromJson<T> fromJson,
  ) async => [];

  @override
  Future<int> count(String entityName) async => _data[entityName]?.length ?? 0;

  @override
  Future<void> deleteFromlist(
    String listName,
    String listId,
    String entityName,
    String id,
  ) async {}
}

class _FakeDidCommAuth extends DIDCommAuth {
  _FakeDidCommAuth({
    required this.authenticationResponse,
    required this.verifyResult,
    required super.storage,
  }) : super(
         privateKey: JWTKey.fromJWK({'kty': 'oct', 'k': 'c2VjcmV0'}),
         publicKey: JWTKey.fromJWK({'kty': 'oct', 'k': 'c2VjcmV0'}),
         jwk: const [],
         logger: _NoOpLogger(),
       );

  final AuthenticationResponse authenticationResponse;
  final VerifyAuthChallengeResult verifyResult;

  @override
  Future<AuthenticationResponse> unpackChallengeResponse(
    String challengeResponse,
  ) async => authenticationResponse;

  @override
  VerifyAuthChallengeResult verifyAuthChallengeToken(
    String did,
    String token,
    ChallengePurpose purpose,
  ) => verifyResult;
}

void main() {
  group('DIDCommAuth.authenticateChallengeResponseWithDetails', () {
    test('returns response details and consumes challenge once', () async {
      final storage = _InMemoryStorage();
      final auth = _FakeDidCommAuth(
        storage: storage,
        authenticationResponse: AuthenticationResponse(
          type: AuthenticationResponseType.didcommChallengeOk,
          did: 'did:key:zalice',
          challenge: 'challenge-token',
          verificationMethod: 'did:key:zalice#key-1',
        ),
        verifyResult: VerifyAuthChallengeResult(
          status: JWTStatus.valid,
          jti: 'challenge-jti',
        ),
      );

      final response = await auth.authenticateChallengeResponseWithDetails(
        challengeResponse: 'response',
        purpose: ChallengePurpose.authenticate,
      );

      expect(response.did, 'did:key:zalice');
      expect(response.verificationMethod, 'did:key:zalice#key-1');
      expect(
        await storage.findOneById<ConsumedChallenge>(
          ConsumedChallenge.entityName,
          'challenge-jti',
          ConsumedChallenge.fromJson,
        ),
        isNotNull,
      );
    });

    test('throws when the challenge was already consumed', () async {
      final storage = _InMemoryStorage();
      final auth = _FakeDidCommAuth(
        storage: storage,
        authenticationResponse: AuthenticationResponse(
          type: AuthenticationResponseType.didcommChallengeOk,
          did: 'did:key:zalice',
          challenge: 'challenge-token',
          verificationMethod: 'did:key:zalice#key-1',
        ),
        verifyResult: VerifyAuthChallengeResult(
          status: JWTStatus.valid,
          jti: 'challenge-jti',
        ),
      );

      await auth.authenticateChallengeResponseWithDetails(
        challengeResponse: 'response',
        purpose: ChallengePurpose.authenticate,
      );

      expect(
        auth.authenticateChallengeResponseWithDetails(
          challengeResponse: 'response',
          purpose: ChallengePurpose.authenticate,
        ),
        throwsA(
          isA<ChallengeAuthException>().having(
            (e) => e.reason,
            'reason',
            'challengeAlreadyUsed',
          ),
        ),
      );
    });
  });
}
