import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:meeting_place_control_plane_api/src/core/entity/entity.dart';
import 'package:meeting_place_control_plane_api/src/core/logger/logger.dart';
import 'package:meeting_place_control_plane_api/src/core/service/did_document/did_document_service.dart';
import 'package:meeting_place_control_plane_api/src/core/storage/exception/already_exists_exception.dart';
import 'package:meeting_place_control_plane_api/src/core/storage/storage.dart';
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
    if (_data[name]!.containsKey(id)) throw AlreadyExists();
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
    if (row == null) return null;
    final entity = fromJson(row);
    if (!conditionFn(entity)) return null;
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

String _jwkK(String rawSecret) =>
    base64Url.encode(utf8.encode(rawSecret)).replaceAll('=', '');

Map<String, dynamic> _octJwk(String rawSecret) => {
  'kty': 'oct',
  'k': _jwkK(rawSecret),
};

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
};

DidDocument _buildResolvedDidDocument({
  required String did,
  required String verificationMethod,
  required Map<String, dynamic> publicKeyJwk,
}) => DidDocument.fromJson(
  jsonEncode({
    '@context': ['https://www.w3.org/ns/did/v1'],
    'id': did,
    'verificationMethod': [
      {
        'id': verificationMethod,
        'type': 'JsonWebKey2020',
        'controller': did,
        'publicKeyJwk': publicKeyJwk,
      },
    ],
    'authentication': [verificationMethod],
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

String _sign(String rawSecret) {
  final key = SecretKey(rawSecret);
  return JWT({'sub': 'test'}).sign(key, algorithm: JWTAlgorithm.HS256);
}

void main() {
  late _InMemoryStorage storage;
  late _FakeDidResolver didResolver;
  late DidDocumentService service;

  const did = 'did:web:example.com:user:alice';
  const authDid = 'did:key:zAlice123';
  const otherAuthDid = 'did:key:zBob456';
  const authVerificationMethod = '$authDid#control-1';
  const otherAuthVerificationMethod = '$otherAuthDid#control-1';
  const secret = 'unit-test-secret-key-for-did-service';
  const authSecret = 'control-did-secret-for-unit-tests';
  const otherAuthSecret = 'other-control-did-secret-for-unit-tests';

  final jwk = _octJwk(secret);
  final authJwk = _octJwk(authSecret);
  final otherAuthJwk = _octJwk(otherAuthSecret);
  final didDocument = _buildDidDocument(did: did, publicKeyJwk: jwk);

  setUp(() {
    storage = _InMemoryStorage();
    didResolver = _FakeDidResolver({
      authDid: _buildResolvedDidDocument(
        did: authDid,
        verificationMethod: authVerificationMethod,
        publicKeyJwk: authJwk,
      ),
      otherAuthDid: _buildResolvedDidDocument(
        did: otherAuthDid,
        verificationMethod: otherAuthVerificationMethod,
        publicKeyJwk: otherAuthJwk,
      ),
    });
    service = DidDocumentService(
      storage: storage,
      didResolver: didResolver,
      logger: _NoOpLogger(),
    );
  });

  group('upload', () {
    test('stores a new document and returns the record', () async {
      final record = await service.upload(
        authDid: authDid,
        didDocument: didDocument,
        controlProof: _buildProof(
          verificationMethod: authVerificationMethod,
          jws: _sign(authSecret),
        ),
        proof: _buildProof(
          verificationMethod: '$did#key-1',
          jws: _sign(secret),
        ),
      );

      expect(record.did, did);
      expect(record.createdBy, authDid);
      expect(record.didDocument, didDocument);
    });

    test('returns existing record when same owner retries', () async {
      await service.upload(
        authDid: authDid,
        didDocument: didDocument,
        controlProof: _buildProof(
          verificationMethod: authVerificationMethod,
          jws: _sign(authSecret),
        ),
        proof: _buildProof(
          verificationMethod: '$did#key-1',
          jws: _sign(secret),
        ),
      );

      final second = await service.upload(
        authDid: authDid,
        didDocument: didDocument,
        controlProof: _buildProof(
          verificationMethod: authVerificationMethod,
          jws: _sign(authSecret),
        ),
        proof: _buildProof(
          verificationMethod: '$did#key-1',
          jws: _sign(secret),
        ),
      );

      expect(second.did, did);
      expect(second.createdBy, authDid);
    });

    test('throws when a different owner claims the same DID', () async {
      await service.upload(
        authDid: authDid,
        didDocument: didDocument,
        controlProof: _buildProof(
          verificationMethod: authVerificationMethod,
          jws: _sign(authSecret),
        ),
        proof: _buildProof(
          verificationMethod: '$did#key-1',
          jws: _sign(secret),
        ),
      );

      expect(
        () => service.upload(
          authDid: otherAuthDid,
          didDocument: didDocument,
          controlProof: _buildProof(
            verificationMethod: otherAuthVerificationMethod,
            jws: _sign(otherAuthSecret),
          ),
          proof: _buildProof(
            verificationMethod: '$did#key-1',
            jws: _sign(secret),
          ),
        ),
        throwsA(isA<InvalidDidDocumentInput>()),
      );
    });

    test('throws on DID that does not match did:web:<host>:user:<segment>', () {
      final badDoc = {
        '@context': ['https://www.w3.org/ns/did/v1'],
        'id': 'did:web:example.com',
        'verificationMethod': [
          {
            'id': 'did:web:example.com#key-1',
            'type': 'JsonWebKey2020',
            'controller': 'did:web:example.com',
            'publicKeyJwk': jwk,
          },
        ],
      };

      expect(
        () => service.upload(
          authDid: authDid,
          didDocument: badDoc,
          controlProof: _buildProof(
            verificationMethod: authVerificationMethod,
            jws: _sign(authSecret),
          ),
          proof: _buildProof(
            verificationMethod: '$did#key-1',
            jws: _sign(secret),
          ),
        ),
        throwsA(isA<InvalidDidDocumentInput>()),
      );
    });

    test(
      'throws on controlProof signed by an unknown authenticated DID key',
      () {
        expect(
          () => service.upload(
            authDid: authDid,
            didDocument: didDocument,
            controlProof: _buildProof(
              verificationMethod: authVerificationMethod,
              jws: _sign('different-secret-not-in-auth-did'),
            ),
            proof: _buildProof(
              verificationMethod: '$did#key-1',
              jws: _sign(secret),
            ),
          ),
          throwsA(isA<InvalidDidDocumentInput>()),
        );
      },
    );

    test('throws on proof signed by an unknown didDocument key', () {
      expect(
        () => service.upload(
          authDid: authDid,
          didDocument: didDocument,
          controlProof: _buildProof(
            verificationMethod: authVerificationMethod,
            jws: _sign(authSecret),
          ),
          proof: _buildProof(
            verificationMethod: '$did#key-1',
            jws: _sign('different-secret-not-in-document'),
          ),
        ),
        throwsA(isA<InvalidDidDocumentInput>()),
      );
    });

    test('throws when DID document has no verification methods', () {
      final docNoKeys = {
        '@context': ['https://www.w3.org/ns/did/v1'],
        'id': did,
      };

      expect(
        () => service.upload(
          authDid: authDid,
          didDocument: docNoKeys,
          controlProof: _buildProof(
            verificationMethod: authVerificationMethod,
            jws: _sign(authSecret),
          ),
          proof: _buildProof(
            verificationMethod: '$did#key-1',
            jws: _sign(secret),
          ),
        ),
        throwsA(isA<InvalidDidDocumentInput>()),
      );
    });

    test('throws when segment is already claimed by a different DID', () async {
      await service.upload(
        authDid: authDid,
        didDocument: didDocument,
        controlProof: _buildProof(
          verificationMethod: authVerificationMethod,
          jws: _sign(authSecret),
        ),
        proof: _buildProof(
          verificationMethod: '$did#key-1',
          jws: _sign(secret),
        ),
      );

      const otherDid = 'did:web:other.com:user:alice';
      final otherSecret = 'other-test-secret-key-for-did-service';
      final otherJwk = _octJwk(otherSecret);
      final otherDoc = _buildDidDocument(did: otherDid, publicKeyJwk: otherJwk);

      expect(
        () => service.upload(
          authDid: otherAuthDid,
          didDocument: otherDoc,
          controlProof: _buildProof(
            verificationMethod: otherAuthVerificationMethod,
            jws: _sign(otherAuthSecret),
          ),
          proof: _buildProof(
            verificationMethod: '$otherDid#key-1',
            jws: _sign(otherSecret),
          ),
        ),
        throwsA(isA<InvalidDidDocumentInput>()),
      );
    });

    test('throws when proof type is wrong', () {
      expect(
        () => service.upload(
          authDid: authDid,
          didDocument: didDocument,
          controlProof: _buildProof(
            verificationMethod: authVerificationMethod,
            jws: _sign(authSecret),
            type: 'Ed25519Signature2018',
          ),
          proof: _buildProof(
            verificationMethod: '$did#key-1',
            jws: _sign(secret),
          ),
        ),
        throwsA(isA<InvalidDidDocumentInput>()),
      );
    });

    test('throws when proof proofPurpose is wrong', () {
      expect(
        () => service.upload(
          authDid: authDid,
          didDocument: didDocument,
          controlProof: _buildProof(
            verificationMethod: authVerificationMethod,
            jws: _sign(authSecret),
          ),
          proof: _buildProof(
            verificationMethod: '$did#key-1',
            jws: _sign(secret),
            proofPurpose: 'assertionMethod',
          ),
        ),
        throwsA(isA<InvalidDidDocumentInput>()),
      );
    });

    test('throws when controlProof verificationMethod is not on authDid', () {
      expect(
        () => service.upload(
          authDid: authDid,
          didDocument: didDocument,
          controlProof: _buildProof(
            verificationMethod: '$authDid#missing',
            jws: _sign(authSecret),
          ),
          proof: _buildProof(
            verificationMethod: '$did#key-1',
            jws: _sign(secret),
          ),
        ),
        throwsA(isA<InvalidDidDocumentInput>()),
      );
    });

    test('throws when proof verificationMethod is not in didDocument', () {
      expect(
        () => service.upload(
          authDid: authDid,
          didDocument: didDocument,
          controlProof: _buildProof(
            verificationMethod: authVerificationMethod,
            jws: _sign(authSecret),
          ),
          proof: _buildProof(
            verificationMethod: '$did#missing',
            jws: _sign(secret),
          ),
        ),
        throwsA(isA<InvalidDidDocumentInput>()),
      );
    });
  });

  group('resolveBySegment', () {
    test('returns the DID document for a known segment', () async {
      await service.upload(
        authDid: authDid,
        didDocument: didDocument,
        controlProof: _buildProof(
          verificationMethod: authVerificationMethod,
          jws: _sign(authSecret),
        ),
        proof: _buildProof(
          verificationMethod: '$did#key-1',
          jws: _sign(secret),
        ),
      );

      final resolved = await service.resolveBySegment('alice');
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
