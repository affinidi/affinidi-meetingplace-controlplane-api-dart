import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:meeting_place_control_plane_api/src/core/entity/entity.dart';
import 'package:meeting_place_control_plane_api/src/core/logger/logger.dart';
import 'package:meeting_place_control_plane_api/src/core/service/did_document/did_document_service.dart';
import 'package:meeting_place_control_plane_api/src/core/storage/exception/already_exists_exception.dart';
import 'package:meeting_place_control_plane_api/src/core/storage/storage.dart';
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

String _jwkK(String rawSecret) =>
    base64Url.encode(utf8.encode(rawSecret)).replaceAll('=', '');

Map<String, dynamic> _octJwk(String rawSecret) => {
  'kty': 'oct',
  'k': _jwkK(rawSecret),
};

Map<String, dynamic> _buildDidDocument({
  required String did,
  required Map<String, dynamic> publicKeyJwk,
  String proofType = 'JsonWebSignature2020',
  String proofPurpose = 'authentication',
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
  'proof': {
    'type': proofType,
    'proofPurpose': proofPurpose,
    'verificationMethod': '$did#key-1',
  },
};

String _sign(String rawSecret) {
  final key = SecretKey(rawSecret);
  return JWT({'sub': 'test'}).sign(key, algorithm: JWTAlgorithm.HS256);
}

void main() {
  late _InMemoryStorage storage;
  late DidDocumentService service;

  const did = 'did:web:example.com:user:alice';
  const authDid = 'did:key:zAlice123';
  const secret = 'unit-test-secret-key-for-did-service';

  final jwk = _octJwk(secret);
  final didDocument = _buildDidDocument(did: did, publicKeyJwk: jwk);

  setUp(() {
    storage = _InMemoryStorage();
    service = DidDocumentService(storage: storage, logger: _NoOpLogger());
  });

  group('upload', () {
    test('stores a new document and returns the record', () async {
      final record = await service.upload(
        authDid: authDid,
        didDocument: didDocument,
        controlProof: _sign(secret),
        proof: _sign(secret),
      );

      expect(record.did, did);
      expect(record.createdBy, authDid);
      expect(record.didDocument, didDocument);
    });

    test('returns existing record when same owner retries', () async {
      await service.upload(
        authDid: authDid,
        didDocument: didDocument,
        controlProof: _sign(secret),
        proof: _sign(secret),
      );

      final second = await service.upload(
        authDid: authDid,
        didDocument: didDocument,
        controlProof: _sign(secret),
        proof: _sign(secret),
      );

      expect(second.did, did);
      expect(second.createdBy, authDid);
    });

    test('throws when a different owner claims the same DID', () async {
      await service.upload(
        authDid: authDid,
        didDocument: didDocument,
        controlProof: _sign(secret),
        proof: _sign(secret),
      );

      expect(
        () => service.upload(
          authDid: 'did:key:zBob456',
          didDocument: didDocument,
          controlProof: _sign(secret),
          proof: _sign(secret),
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
          controlProof: _sign(secret),
          proof: _sign(secret),
        ),
        throwsA(isA<InvalidDidDocumentInput>()),
      );
    });

    test('throws on proof signed by an unknown key', () {
      expect(
        () => service.upload(
          authDid: authDid,
          didDocument: didDocument,
          controlProof: _sign('different-secret-not-in-document'),
          proof: _sign(secret),
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
          controlProof: _sign(secret),
          proof: _sign(secret),
        ),
        throwsA(isA<InvalidDidDocumentInput>()),
      );
    });

    test('throws when segment is already claimed by a different DID', () async {
      await service.upload(
        authDid: authDid,
        didDocument: didDocument,
        controlProof: _sign(secret),
        proof: _sign(secret),
      );

      const otherDid = 'did:web:other.com:user:alice';
      final otherSecret = 'other-test-secret-key-for-did-service';
      final otherJwk = _octJwk(otherSecret);
      final otherDoc = _buildDidDocument(did: otherDid, publicKeyJwk: otherJwk);

      expect(
        () => service.upload(
          authDid: 'did:key:zBob456',
          didDocument: otherDoc,
          controlProof: _sign(otherSecret),
          proof: _sign(otherSecret),
        ),
        throwsA(isA<InvalidDidDocumentInput>()),
      );
    });

    test('throws when embedded proof type is wrong', () {
      final badDoc = _buildDidDocument(
        did: did,
        publicKeyJwk: jwk,
        proofType: 'Ed25519Signature2018',
      );
      expect(
        () => service.upload(
          authDid: authDid,
          didDocument: badDoc,
          controlProof: _sign(secret),
          proof: _sign(secret),
        ),
        throwsA(isA<InvalidDidDocumentInput>()),
      );
    });

    test('throws when embedded proof proofPurpose is wrong', () {
      final badDoc = _buildDidDocument(
        did: did,
        publicKeyJwk: jwk,
        proofPurpose: 'assertionMethod',
      );
      expect(
        () => service.upload(
          authDid: authDid,
          didDocument: badDoc,
          controlProof: _sign(secret),
          proof: _sign(secret),
        ),
        throwsA(isA<InvalidDidDocumentInput>()),
      );
    });

    test('throws when embedded proof is missing', () {
      final docNoProof = {
        '@context': ['https://www.w3.org/ns/did/v1'],
        'id': did,
        'verificationMethod': [
          {
            'id': '$did#key-1',
            'type': 'JsonWebKey2020',
            'controller': did,
            'publicKeyJwk': jwk,
          },
        ],
      };
      expect(
        () => service.upload(
          authDid: authDid,
          didDocument: docNoProof,
          controlProof: _sign(secret),
          proof: _sign(secret),
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
        controlProof: _sign(secret),
        proof: _sign(secret),
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
