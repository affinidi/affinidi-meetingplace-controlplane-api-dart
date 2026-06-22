import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:meeting_place_control_plane_api/src/core/entity/entity.dart';
import 'package:meeting_place_control_plane_api/src/core/logger/logger.dart';
import 'package:meeting_place_control_plane_api/src/core/service/did_document/did_document_service.dart';
import 'package:meeting_place_control_plane_api/src/core/storage/exception/already_exists_exception.dart';
import 'package:meeting_place_control_plane_api/src/core/storage/storage.dart';
import 'package:meeting_place_control_plane_api/src/utils/jcs_serializer.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

class _InMemoryStorage implements Storage {
  final _data = <String, Map<String, Map<String, dynamic>>>{};

  @override
  Future<Storage> connect() async => this;

  @override
  Future<T> create<T extends Entity>(T object) async {
    final name = object.getEntityName();
    final id = object.getId();
    _data.putIfAbsent(name, () => {});
    if (_data[name]!.containsKey(id)) {
      throw AlreadyExists();
    }
    _data[name]![id] = object.toJson();
    return object;
  }

  @override
  Future<T> update<T extends Entity>(T object) async {
    _data.putIfAbsent(object.getEntityName(), () => {});
    _data[object.getEntityName()]![object.getId()] = object.toJson();
    return object;
  }

  @override
  Future<T?> updateWithCondition<T extends Entity>(
    String entityName,
    String id,
    EntityFromJson<T> fromJson, {
    required T Function(T entity) updateFn,
    required bool Function(T entity) conditionFn,
  }) async {
    final row = _data[entityName]?[id];
    if (row == null) {
      return null;
    }
    final entity = fromJson(row);
    if (!conditionFn(entity)) {
      return null;
    }
    final updated = updateFn(entity);
    _data[entityName]![id] = updated.toJson();
    return updated;
  }

  @override
  Future<T> add<T extends Entity>(String listName, T object) async =>
      create(object);

  @override
  Future<void> delete(String entityName, String id) async =>
      _data[entityName]?.remove(id);

  @override
  Future<T?> findOneById<T extends Entity>(
    String entityName,
    String id,
    EntityFromJson<T> fromJson,
  ) async {
    final row = _data[entityName]?[id];
    return row == null ? null : fromJson(row);
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

class _FakeDidResolver implements DidResolver {
  _FakeDidResolver(this._documents);

  final Map<String, DidDocument> _documents;

  @override
  Future<DidDocument> resolveDid(String did) async {
    final document = _documents[did];
    if (document == null) {
      throw Exception('Missing DID document for $did');
    }
    return document;
  }
}

Map<String, dynamic> _buildDidDocument({
  required String did,
  required Map<String, dynamic> publicKeyJwk,
}) => {
  '@context': ['https://www.w3.org/ns/did/v1'],
  'id': did,
  'verificationMethod': [
    {
      'id': '$did#key-1',
      'type': 'JsonWebKey2020',
      'controller': did,
      'publicKeyJwk': publicKeyJwk,
    },
  ],
  'authentication': ['$did#key-1'],
};

DidDocument _buildResolvedDidDocument({
  required String did,
  required List<
    ({String verificationMethod, Map<String, dynamic> publicKeyJwk})
  >
  methods,
}) => DidDocument.fromJson(
  jsonEncode({
    '@context': ['https://www.w3.org/ns/did/v1'],
    'id': did,
    'verificationMethod': methods
        .map(
          (method) => {
            'id': method.verificationMethod,
            'type': 'JsonWebKey2020',
            'controller': did,
            'publicKeyJwk': method.publicKeyJwk,
          },
        )
        .toList(),
    'authentication': methods
        .map((method) => method.verificationMethod)
        .toList(),
  }),
);

Map<String, dynamic> _buildProof({
  required String verificationMethod,
  required String jws,
  String type = 'JsonWebSignature2020',
  String proofPurpose = 'authentication',
}) => {
  'type': type,
  'created': '2026-01-01T00:00:00Z',
  'verificationMethod': verificationMethod,
  'proofPurpose': proofPurpose,
  'jws': jws,
};

Map<String, dynamic> _proofPayload({
  required Map<String, dynamic> didDocument,
  required String authDid,
  int? iat,
  int? exp,
  String jti = 'proof-jti',
}) {
  final issuedAt = iat ?? DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
  final expiresAt = exp ?? issuedAt + 60;
  final didDocumentHash = base64Url
      .encode(
        sha256.convert(jcsSerializer.serializeObjectToUtf8(didDocument)).bytes,
      )
      .replaceAll('=', '');
  return {
    'operation': 'did-document/upload',
    'didDocumentId': didDocument['id'],
    'didDocumentHash': didDocumentHash,
    'controlDid': authDid,
    'aud': 'https://example.com',
    'iat': issuedAt,
    'exp': expiresAt,
    'jti': jti,
  };
}

Future<String> _signProof({
  required PersistentWallet wallet,
  required String keyId,
  required String verificationMethod,
  required Map<String, dynamic> payload,
  SignatureScheme signatureScheme = SignatureScheme.ecdsa_p256_sha256,
}) async {
  final encodedHeader = base64Url
      .encode(
        utf8.encode(
          jsonEncode({'alg': signatureScheme.alg, 'kid': verificationMethod}),
        ),
      )
      .replaceAll('=', '');
  final encodedPayload = base64Url
      .encode(utf8.encode(jsonEncode(payload)))
      .replaceAll('=', '');
  final signingInput = Uint8List.fromList(
    utf8.encode('$encodedHeader.$encodedPayload'),
  );
  final signature = await wallet.sign(
    signingInput,
    keyId: keyId,
    signatureScheme: signatureScheme,
  );
  final encodedSignature = base64Url.encode(signature).replaceAll('=', '');
  return '$encodedHeader.$encodedPayload.$encodedSignature';
}

Future<Map<String, dynamic>> _buildSignedProof({
  required PersistentWallet wallet,
  required String keyId,
  required String verificationMethod,
  required Map<String, dynamic> payload,
  String type = 'JsonWebSignature2020',
  String proofPurpose = 'authentication',
}) async {
  return _buildProof(
    verificationMethod: verificationMethod,
    jws: await _signProof(
      wallet: wallet,
      keyId: keyId,
      verificationMethod: verificationMethod,
      payload: payload,
    ),
    type: type,
    proofPurpose: proofPurpose,
  );
}

Future<({Map<String, dynamic> controlProof, Map<String, dynamic> proof})>
_buildValidProofs({
  required PersistentWallet authWallet,
  required String authKeyId,
  required String authVerificationMethod,
  required PersistentWallet didWallet,
  required String didKeyId,
  required Map<String, dynamic> didDocument,
  required String authDid,
  int? iat,
  int? exp,
  String jti = 'proof-jti',
}) async {
  final payload = _proofPayload(
    didDocument: didDocument,
    authDid: authDid,
    iat: iat,
    exp: exp,
    jti: jti,
  );
  return (
    controlProof: await _buildSignedProof(
      wallet: authWallet,
      keyId: authKeyId,
      verificationMethod: authVerificationMethod,
      payload: payload,
    ),
    proof: await _buildSignedProof(
      wallet: didWallet,
      keyId: didKeyId,
      verificationMethod: '${didDocument['id']}#key-1',
      payload: payload,
    ),
  );
}

void main() {
  late _InMemoryStorage storage;
  late _FakeDidResolver didResolver;
  late DidDocumentService service;
  late PersistentWallet authWallet;
  late PersistentWallet secondAuthWallet;
  late PersistentWallet otherAuthWallet;
  late PersistentWallet didWallet;
  late PersistentWallet rogueWallet;
  late String authKeyId;
  late String secondAuthKeyId;
  late String otherAuthKeyId;
  late String didKeyId;
  late String rogueKeyId;
  late Map<String, dynamic> authJwk;
  late Map<String, dynamic> secondAuthJwk;
  late Map<String, dynamic> otherAuthJwk;
  late Map<String, dynamic> didJwk;
  late Map<String, dynamic> didDocument;

  const did = 'did:web:example.com:user:a1b2c3d4-e5f6-4789-8901-abcdef012345';
  const authDid = 'did:key:zAlice123';
  const otherAuthDid = 'did:key:zBob456';
  const authVerificationMethod = '$authDid#control-1';
  const secondAuthVerificationMethod = '$authDid#control-2';
  const otherAuthVerificationMethod = '$otherAuthDid#control-1';
  const proofAudience = 'https://example.com';
  const hostedDidHost = 'example.com';

  setUp(() async {
    storage = _InMemoryStorage();
    authWallet = PersistentWallet(InMemoryKeyStore());
    secondAuthWallet = PersistentWallet(InMemoryKeyStore());
    otherAuthWallet = PersistentWallet(InMemoryKeyStore());
    didWallet = PersistentWallet(InMemoryKeyStore());
    rogueWallet = PersistentWallet(InMemoryKeyStore());

    authKeyId = (await authWallet.generateKey(keyType: KeyType.p256)).id;
    secondAuthKeyId = (await secondAuthWallet.generateKey(
      keyType: KeyType.p256,
    )).id;
    otherAuthKeyId = (await otherAuthWallet.generateKey(
      keyType: KeyType.p256,
    )).id;
    didKeyId = (await didWallet.generateKey(keyType: KeyType.p256)).id;
    rogueKeyId = (await rogueWallet.generateKey(keyType: KeyType.p256)).id;

    authJwk = keyToJwk(await authWallet.getPublicKey(authKeyId));
    secondAuthJwk = keyToJwk(
      await secondAuthWallet.getPublicKey(secondAuthKeyId),
    );
    otherAuthJwk = keyToJwk(await otherAuthWallet.getPublicKey(otherAuthKeyId));
    didJwk = keyToJwk(await didWallet.getPublicKey(didKeyId));
    didDocument = _buildDidDocument(did: did, publicKeyJwk: didJwk);

    didResolver = _FakeDidResolver({
      authDid: _buildResolvedDidDocument(
        did: authDid,
        methods: [
          (verificationMethod: authVerificationMethod, publicKeyJwk: authJwk),
          (
            verificationMethod: secondAuthVerificationMethod,
            publicKeyJwk: secondAuthJwk,
          ),
        ],
      ),
      otherAuthDid: _buildResolvedDidDocument(
        did: otherAuthDid,
        methods: [
          (
            verificationMethod: otherAuthVerificationMethod,
            publicKeyJwk: otherAuthJwk,
          ),
        ],
      ),
    });
    service = DidDocumentService(
      storage: storage,
      didResolver: didResolver,
      proofAudience: proofAudience,
      hostedDidHost: hostedDidHost,
      logger: _NoOpLogger(),
    );
  });

  group('upload', () {
    test('stores a new document and returns the record', () async {
      final proofs = await _buildValidProofs(
        authWallet: authWallet,
        authKeyId: authKeyId,
        authVerificationMethod: authVerificationMethod,
        didWallet: didWallet,
        didKeyId: didKeyId,
        didDocument: didDocument,
        authDid: authDid,
      );

      final record = await service.upload(
        authDid: authDid,
        authVerificationMethod: authVerificationMethod,
        didDocument: didDocument,
        controlProof: proofs.controlProof,
        proof: proofs.proof,
      );

      expect(record.did, did);
      expect(record.createdBy, authDid);
      expect(record.createdByVerificationMethod, authVerificationMethod);
      expect(record.didDocument, didDocument);
    });

    test('returns existing record when same owner retries', () async {
      final proofs = await _buildValidProofs(
        authWallet: authWallet,
        authKeyId: authKeyId,
        authVerificationMethod: authVerificationMethod,
        didWallet: didWallet,
        didKeyId: didKeyId,
        didDocument: didDocument,
        authDid: authDid,
        jti: 'proof-jti-first',
      );

      await service.upload(
        authDid: authDid,
        authVerificationMethod: authVerificationMethod,
        didDocument: didDocument,
        controlProof: proofs.controlProof,
        proof: proofs.proof,
      );

      final second = await service.upload(
        authDid: authDid,
        authVerificationMethod: authVerificationMethod,
        didDocument: didDocument,
        controlProof: (await _buildValidProofs(
          authWallet: authWallet,
          authKeyId: authKeyId,
          authVerificationMethod: authVerificationMethod,
          didWallet: didWallet,
          didKeyId: didKeyId,
          didDocument: didDocument,
          authDid: authDid,
          jti: 'proof-jti-second',
        )).controlProof,
        proof: (await _buildValidProofs(
          authWallet: authWallet,
          authKeyId: authKeyId,
          authVerificationMethod: authVerificationMethod,
          didWallet: didWallet,
          didKeyId: didKeyId,
          didDocument: didDocument,
          authDid: authDid,
          jti: 'proof-jti-second',
        )).proof,
      );

      expect(second.did, did);
      expect(second.createdBy, authDid);
      expect(second.createdByVerificationMethod, authVerificationMethod);
    });

    test('throws when same DID uses a different authenticated key', () async {
      final proofs = await _buildValidProofs(
        authWallet: authWallet,
        authKeyId: authKeyId,
        authVerificationMethod: authVerificationMethod,
        didWallet: didWallet,
        didKeyId: didKeyId,
        didDocument: didDocument,
        authDid: authDid,
        jti: 'proof-jti-first',
      );

      await service.upload(
        authDid: authDid,
        authVerificationMethod: authVerificationMethod,
        didDocument: didDocument,
        controlProof: proofs.controlProof,
        proof: proofs.proof,
      );

      final secondKeyProofs = await _buildValidProofs(
        authWallet: secondAuthWallet,
        authKeyId: secondAuthKeyId,
        authVerificationMethod: secondAuthVerificationMethod,
        didWallet: didWallet,
        didKeyId: didKeyId,
        didDocument: didDocument,
        authDid: authDid,
        jti: 'proof-jti-second',
      );

      expect(
        service.upload(
          authDid: authDid,
          authVerificationMethod: secondAuthVerificationMethod,
          didDocument: didDocument,
          controlProof: secondKeyProofs.controlProof,
          proof: secondKeyProofs.proof,
        ),
        throwsA(isA<DidDocumentConflict>()),
      );
    });

    test('throws when same owner retries with a different document', () async {
      final proofs = await _buildValidProofs(
        authWallet: authWallet,
        authKeyId: authKeyId,
        authVerificationMethod: authVerificationMethod,
        didWallet: didWallet,
        didKeyId: didKeyId,
        didDocument: didDocument,
        authDid: authDid,
        jti: 'proof-jti-first',
      );

      await service.upload(
        authDid: authDid,
        authVerificationMethod: authVerificationMethod,
        didDocument: didDocument,
        controlProof: proofs.controlProof,
        proof: proofs.proof,
      );

      final updatedDoc = {
        ...didDocument,
        'service': [
          {
            'id': '$did#didcomm',
            'type': 'DIDCommMessaging',
            'serviceEndpoint': {'uri': 'did:example:mediator'},
          },
        ],
      };
      final updatedProofs = await _buildValidProofs(
        authWallet: authWallet,
        authKeyId: authKeyId,
        authVerificationMethod: authVerificationMethod,
        didWallet: didWallet,
        didKeyId: didKeyId,
        didDocument: updatedDoc,
        authDid: authDid,
        jti: 'proof-jti-second',
      );

      expect(
        service.upload(
          authDid: authDid,
          authVerificationMethod: authVerificationMethod,
          didDocument: updatedDoc,
          controlProof: updatedProofs.controlProof,
          proof: updatedProofs.proof,
        ),
        throwsA(isA<DidDocumentConflict>()),
      );
    });

    test('throws when a different owner claims the same DID', () async {
      final proofs = await _buildValidProofs(
        authWallet: authWallet,
        authKeyId: authKeyId,
        authVerificationMethod: authVerificationMethod,
        didWallet: didWallet,
        didKeyId: didKeyId,
        didDocument: didDocument,
        authDid: authDid,
        jti: 'proof-jti-first',
      );

      await service.upload(
        authDid: authDid,
        authVerificationMethod: authVerificationMethod,
        didDocument: didDocument,
        controlProof: proofs.controlProof,
        proof: proofs.proof,
      );

      final otherProofs = await _buildValidProofs(
        authWallet: otherAuthWallet,
        authKeyId: otherAuthKeyId,
        authVerificationMethod: otherAuthVerificationMethod,
        didWallet: didWallet,
        didKeyId: didKeyId,
        didDocument: didDocument,
        authDid: otherAuthDid,
        jti: 'proof-jti-second',
      );

      expect(
        service.upload(
          authDid: otherAuthDid,
          authVerificationMethod: otherAuthVerificationMethod,
          didDocument: didDocument,
          controlProof: otherProofs.controlProof,
          proof: otherProofs.proof,
        ),
        throwsA(isA<DidDocumentConflict>()),
      );
    });

    test(
      'throws on DID that does not match did:web:<host>:user:<segment>',
      () async {
        final badDoc = {
          '@context': ['https://www.w3.org/ns/did/v1'],
          'id': 'did:web:example.com',
          'verificationMethod': [
            {
              'id': 'did:web:example.com#key-1',
              'type': 'JsonWebKey2020',
              'controller': 'did:web:example.com',
              'publicKeyJwk': didJwk,
            },
          ],
        };
        final payload = _proofPayload(didDocument: badDoc, authDid: authDid);
        final controlProof = await _buildSignedProof(
          wallet: authWallet,
          keyId: authKeyId,
          verificationMethod: authVerificationMethod,
          payload: payload,
        );
        final proof = await _buildSignedProof(
          wallet: didWallet,
          keyId: didKeyId,
          verificationMethod: '${badDoc['id']}#key-1',
          payload: payload,
        );

        expect(
          service.upload(
            authDid: authDid,
            authVerificationMethod: authVerificationMethod,
            didDocument: badDoc,
            controlProof: controlProof,
            proof: proof,
          ),
          throwsA(isA<InvalidDidDocumentInput>()),
        );
      },
    );

    test(
      'throws on controlProof signed by an unknown authenticated DID key',
      () async {
        final payload = _proofPayload(
          didDocument: didDocument,
          authDid: authDid,
        );
        final controlProof = await _buildSignedProof(
          wallet: rogueWallet,
          keyId: rogueKeyId,
          verificationMethod: authVerificationMethod,
          payload: payload,
        );
        final proof = await _buildSignedProof(
          wallet: didWallet,
          keyId: didKeyId,
          verificationMethod: '$did#key-1',
          payload: payload,
        );

        expect(
          service.upload(
            authDid: authDid,
            authVerificationMethod: authVerificationMethod,
            didDocument: didDocument,
            controlProof: controlProof,
            proof: proof,
          ),
          throwsA(isA<InvalidDidDocumentInput>()),
        );
      },
    );

    test('throws on proof signed by an unknown didDocument key', () async {
      final payload = _proofPayload(didDocument: didDocument, authDid: authDid);
      final controlProof = await _buildSignedProof(
        wallet: authWallet,
        keyId: authKeyId,
        verificationMethod: authVerificationMethod,
        payload: payload,
      );
      final proof = await _buildSignedProof(
        wallet: rogueWallet,
        keyId: rogueKeyId,
        verificationMethod: '$did#key-1',
        payload: payload,
      );

      expect(
        service.upload(
          authDid: authDid,
          authVerificationMethod: authVerificationMethod,
          didDocument: didDocument,
          controlProof: controlProof,
          proof: proof,
        ),
        throwsA(isA<InvalidDidDocumentInput>()),
      );
    });

    test('throws when proof has expired', () async {
      final nowEpoch = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      final expiredPayload = _proofPayload(
        didDocument: didDocument,
        authDid: authDid,
        iat: nowEpoch - 120,
        exp: nowEpoch - 60,
      );
      final controlProof = await _buildSignedProof(
        wallet: authWallet,
        keyId: authKeyId,
        verificationMethod: authVerificationMethod,
        payload: expiredPayload,
      );
      final proof = await _buildSignedProof(
        wallet: didWallet,
        keyId: didKeyId,
        verificationMethod: '$did#key-1',
        payload: expiredPayload,
      );

      expect(
        service.upload(
          authDid: authDid,
          authVerificationMethod: authVerificationMethod,
          didDocument: didDocument,
          controlProof: controlProof,
          proof: proof,
        ),
        throwsA(isA<InvalidDidDocumentInput>()),
      );
    });

    test(
      'throws when proof window is too large even if exp is still future',
      () async {
        final nowEpoch = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
        final proofs = await _buildValidProofs(
          authWallet: authWallet,
          authKeyId: authKeyId,
          authVerificationMethod: authVerificationMethod,
          didWallet: didWallet,
          didKeyId: didKeyId,
          didDocument: didDocument,
          authDid: authDid,
          iat: nowEpoch - 86400,
          exp: nowEpoch + 300,
          jti: 'proof-jti-too-old',
        );

        expect(
          service.upload(
            authDid: authDid,
            authVerificationMethod: authVerificationMethod,
            didDocument: didDocument,
            controlProof: proofs.controlProof,
            proof: proofs.proof,
          ),
          throwsA(isA<InvalidDidDocumentInput>()),
        );
      },
    );

    test('throws when the same proof JTI is replayed', () async {
      final proofs = await _buildValidProofs(
        authWallet: authWallet,
        authKeyId: authKeyId,
        authVerificationMethod: authVerificationMethod,
        didWallet: didWallet,
        didKeyId: didKeyId,
        didDocument: didDocument,
        authDid: authDid,
        jti: 'proof-jti-replay',
      );

      await service.upload(
        authDid: authDid,
        authVerificationMethod: authVerificationMethod,
        didDocument: didDocument,
        controlProof: proofs.controlProof,
        proof: proofs.proof,
      );

      expect(
        service.upload(
          authDid: authDid,
          authVerificationMethod: authVerificationMethod,
          didDocument: didDocument,
          controlProof: proofs.controlProof,
          proof: proofs.proof,
        ),
        throwsA(isA<DidDocumentConflict>()),
      );
    });

    test(
      'throws when the proof payload claims do not match each other',
      () async {
        final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
        final controlPayload = _proofPayload(
          didDocument: didDocument,
          authDid: authDid,
          iat: now,
          exp: now + 60,
        );
        final proofPayload = _proofPayload(
          didDocument: didDocument,
          authDid: authDid,
          iat: now - 1,
          exp: now + 59,
        );
        final controlProof = await _buildSignedProof(
          wallet: authWallet,
          keyId: authKeyId,
          verificationMethod: authVerificationMethod,
          payload: controlPayload,
        );
        final proof = await _buildSignedProof(
          wallet: didWallet,
          keyId: didKeyId,
          verificationMethod: '$did#key-1',
          payload: proofPayload,
        );

        expect(
          service.upload(
            authDid: authDid,
            authVerificationMethod: authVerificationMethod,
            didDocument: didDocument,
            controlProof: controlProof,
            proof: proof,
          ),
          throwsA(isA<InvalidDidDocumentInput>()),
        );
      },
    );

    test(
      'accepts embedded authentication verification methods without a top-level verificationMethod',
      () async {
        final didWithEmbeddedAuth = {
          '@context': didDocument['@context'],
          'id': did,
          'authentication': [
            {
              'id': '$did#key-1',
              'type': 'JsonWebKey2020',
              'controller': did,
              'publicKeyJwk': didJwk,
            },
          ],
        };
        final proofs = await _buildValidProofs(
          authWallet: authWallet,
          authKeyId: authKeyId,
          authVerificationMethod: authVerificationMethod,
          didWallet: didWallet,
          didKeyId: didKeyId,
          didDocument: didWithEmbeddedAuth,
          authDid: authDid,
          jti: 'proof-jti-embedded-auth',
        );

        final record = await service.upload(
          authDid: authDid,
          authVerificationMethod: authVerificationMethod,
          didDocument: didWithEmbeddedAuth,
          controlProof: proofs.controlProof,
          proof: proofs.proof,
        );

        expect(record.did, did);
      },
    );

    test('accepts did:web hosts with encoded ports', () async {
      const didWithPort =
          'did:web:example.com%3A3000:user:a1b2c3d4-e5f6-4789-8901-abcdef012345';
      final didDocumentWithPort = _buildDidDocument(
        did: didWithPort,
        publicKeyJwk: didJwk,
      );
      final proofs = await _buildValidProofs(
        authWallet: authWallet,
        authKeyId: authKeyId,
        authVerificationMethod: authVerificationMethod,
        didWallet: didWallet,
        didKeyId: didKeyId,
        didDocument: didDocumentWithPort,
        authDid: authDid,
        jti: 'proof-jti-port-host',
      );
      final portAwareService = DidDocumentService(
        storage: storage,
        didResolver: didResolver,
        proofAudience: proofAudience,
        hostedDidHost: 'example.com:3000',
        logger: _NoOpLogger(),
      );

      final record = await portAwareService.upload(
        authDid: authDid,
        authVerificationMethod: authVerificationMethod,
        didDocument: didDocumentWithPort,
        controlProof: proofs.controlProof,
        proof: proofs.proof,
      );

      expect(record.did, didWithPort);
    });

    test('throws when DID document has no verification methods', () async {
      final docNoKeys = {
        '@context': ['https://www.w3.org/ns/did/v1'],
        'id': did,
      };
      final payload = _proofPayload(didDocument: docNoKeys, authDid: authDid);
      final controlProof = await _buildSignedProof(
        wallet: authWallet,
        keyId: authKeyId,
        verificationMethod: authVerificationMethod,
        payload: payload,
      );
      final proof = await _buildSignedProof(
        wallet: didWallet,
        keyId: didKeyId,
        verificationMethod: '$did#key-1',
        payload: payload,
      );

      expect(
        service.upload(
          authDid: authDid,
          authVerificationMethod: authVerificationMethod,
          didDocument: docNoKeys,
          controlProof: controlProof,
          proof: proof,
        ),
        throwsA(isA<InvalidDidDocumentInput>()),
      );
    });

    test(
      'throws when did:web host does not match the configured host',
      () async {
        const otherDid =
            'did:web:other.com:user:a1b2c3d4-e5f6-4789-8901-abcdef012345';
        final otherDoc = _buildDidDocument(did: otherDid, publicKeyJwk: didJwk);
        final payload = _proofPayload(
          didDocument: otherDoc,
          authDid: otherAuthDid,
        );
        final controlProof = await _buildSignedProof(
          wallet: otherAuthWallet,
          keyId: otherAuthKeyId,
          verificationMethod: otherAuthVerificationMethod,
          payload: payload,
        );
        final proof = await _buildSignedProof(
          wallet: didWallet,
          keyId: didKeyId,
          verificationMethod: '$otherDid#key-1',
          payload: payload,
        );

        expect(
          service.upload(
            authDid: otherAuthDid,
            authVerificationMethod: otherAuthVerificationMethod,
            didDocument: otherDoc,
            controlProof: controlProof,
            proof: proof,
          ),
          throwsA(isA<InvalidDidDocumentInput>()),
        );
      },
    );

    test('throws when proof type is wrong', () async {
      final proofs = await _buildValidProofs(
        authWallet: authWallet,
        authKeyId: authKeyId,
        authVerificationMethod: authVerificationMethod,
        didWallet: didWallet,
        didKeyId: didKeyId,
        didDocument: didDocument,
        authDid: authDid,
      );
      proofs.controlProof['type'] = 'Ed25519Signature2018';

      expect(
        service.upload(
          authDid: authDid,
          authVerificationMethod: authVerificationMethod,
          didDocument: didDocument,
          controlProof: proofs.controlProof,
          proof: proofs.proof,
        ),
        throwsA(isA<InvalidDidDocumentInput>()),
      );
    });

    test('throws when proof proofPurpose is wrong', () async {
      final proofs = await _buildValidProofs(
        authWallet: authWallet,
        authKeyId: authKeyId,
        authVerificationMethod: authVerificationMethod,
        didWallet: didWallet,
        didKeyId: didKeyId,
        didDocument: didDocument,
        authDid: authDid,
      );
      proofs.proof['proofPurpose'] = 'assertionMethod';

      expect(
        service.upload(
          authDid: authDid,
          authVerificationMethod: authVerificationMethod,
          didDocument: didDocument,
          controlProof: proofs.controlProof,
          proof: proofs.proof,
        ),
        throwsA(isA<InvalidDidDocumentInput>()),
      );
    });

    test(
      'throws when controlProof verificationMethod does not match the authenticated key',
      () async {
        final proofs = await _buildValidProofs(
          authWallet: authWallet,
          authKeyId: authKeyId,
          authVerificationMethod: authVerificationMethod,
          didWallet: didWallet,
          didKeyId: didKeyId,
          didDocument: didDocument,
          authDid: authDid,
        );
        proofs.controlProof['verificationMethod'] = '$authDid#missing';

        expect(
          service.upload(
            authDid: authDid,
            authVerificationMethod: authVerificationMethod,
            didDocument: didDocument,
            controlProof: proofs.controlProof,
            proof: proofs.proof,
          ),
          throwsA(isA<InvalidDidDocumentInput>()),
        );
      },
    );

    test(
      'throws when proof verificationMethod is not in didDocument',
      () async {
        final proofs = await _buildValidProofs(
          authWallet: authWallet,
          authKeyId: authKeyId,
          authVerificationMethod: authVerificationMethod,
          didWallet: didWallet,
          didKeyId: didKeyId,
          didDocument: didDocument,
          authDid: authDid,
        );
        proofs.proof['verificationMethod'] = '$did#missing';

        expect(
          service.upload(
            authDid: authDid,
            authVerificationMethod: authVerificationMethod,
            didDocument: didDocument,
            controlProof: proofs.controlProof,
            proof: proofs.proof,
          ),
          throwsA(isA<InvalidDidDocumentInput>()),
        );
      },
    );

    test(
      'throws when proof payload does not match the upload request',
      () async {
        final wrongPayload = _proofPayload(
          didDocument: {
            ...didDocument,
            'service': [
              {
                'id': '$did#didcomm',
                'type': 'DIDCommMessaging',
                'serviceEndpoint': {'uri': 'did:example:other'},
              },
            ],
          },
          authDid: authDid,
        );
        final controlProof = await _buildSignedProof(
          wallet: authWallet,
          keyId: authKeyId,
          verificationMethod: authVerificationMethod,
          payload: wrongPayload,
        );
        final proof = await _buildSignedProof(
          wallet: didWallet,
          keyId: didKeyId,
          verificationMethod: '$did#key-1',
          payload: wrongPayload,
        );

        expect(
          service.upload(
            authDid: authDid,
            authVerificationMethod: authVerificationMethod,
            didDocument: didDocument,
            controlProof: controlProof,
            proof: proof,
          ),
          throwsA(isA<InvalidDidDocumentInput>()),
        );
      },
    );
  });

  group('resolveBySegment', () {
    test('returns the DID document for a known segment', () async {
      final proofs = await _buildValidProofs(
        authWallet: authWallet,
        authKeyId: authKeyId,
        authVerificationMethod: authVerificationMethod,
        didWallet: didWallet,
        didKeyId: didKeyId,
        didDocument: didDocument,
        authDid: authDid,
      );

      await service.upload(
        authDid: authDid,
        authVerificationMethod: authVerificationMethod,
        didDocument: didDocument,
        controlProof: proofs.controlProof,
        proof: proofs.proof,
      );

      final resolved = await service.resolveBySegment(
        'a1b2c3d4-e5f6-4789-8901-abcdef012345',
      );
      expect(resolved['id'], did);
    });

    test('throws DidDocumentNotFound for an unknown segment', () {
      expect(
        () => service.resolveBySegment('unknown'),
        throwsA(isA<DidDocumentNotFound>()),
      );
    });
  });
}
