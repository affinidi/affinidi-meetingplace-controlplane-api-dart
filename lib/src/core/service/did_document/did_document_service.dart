import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:ssi/ssi.dart';

import '../../entity/did_document_record.dart';
import '../../entity/did_document_segment_record.dart';
import '../../logger/logger.dart';
import '../../storage/exception/already_exists_exception.dart';
import '../../storage/storage.dart';

class DidDocumentNotFound implements Exception {}

class InvalidDidDocumentInput implements Exception {
  InvalidDidDocumentInput(this.message);
  final String message;
}

class DidDocumentService {
  DidDocumentService({
    required Storage storage,
    required DidResolver didResolver,
    required Logger logger,
  }) : _storage = storage,
       _didResolver = didResolver,
       _logger = logger;

  final Storage _storage;
  final DidResolver _didResolver;
  final Logger _logger;

  Future<DidDocumentRecord> upload({
    required String authDid,
    required Map<String, dynamic> didDocument,
    required Map<String, dynamic> controlProof,
    required Map<String, dynamic> proof,
  }) async {
    final did = _extractAndValidateDid(didDocument);
    final parsedControlProof = _DidDocumentProof.fromJson(
      controlProof,
      fieldName: 'controlProof',
    );
    final parsedProof = _DidDocumentProof.fromJson(proof, fieldName: 'proof');
    await _verifyControlProof(authDid, parsedControlProof);
    _verifyDidDocumentProof(didDocument, parsedProof);
    final segment = _segmentFromDid(did);
    final now = DateTime.now().toUtc();

    final existing = await _storage.findOneById<DidDocumentRecord>(
      DidDocumentRecord.entityName,
      did,
      DidDocumentRecord.fromJson,
    );
    if (existing != null) {
      if (existing.createdBy != authDid) {
        throw InvalidDidDocumentInput('DID already registered by another user');
      }
      // Backfill segment mapping if a prior partial write left it missing.
      try {
        await _storage.create(
          DidDocumentSegmentRecord(segment: segment, did: did),
        );
      } on AlreadyExists {
        // Segment already exists — idempotent.
      }
      return existing;
    }

    // Verify no other DID has already claimed this segment before persisting
    // the record, to prevent partial state where a DidDocumentRecord exists
    // but segment resolution points to a different DID.
    final segmentConflict = await _storage
        .findOneById<DidDocumentSegmentRecord>(
          DidDocumentSegmentRecord.entityName,
          segment,
          DidDocumentSegmentRecord.fromJson,
        );
    if (segmentConflict != null && segmentConflict.did != did) {
      throw InvalidDidDocumentInput('Segment already claimed by another DID');
    }

    final record = DidDocumentRecord(
      did: did,
      createdBy: authDid,
      createdAt: now,
      updatedAt: now,
      didDocument: didDocument,
    );

    await _storage.create(record);
    try {
      await _storage.create(
        DidDocumentSegmentRecord(segment: segment, did: did),
      );
    } on AlreadyExists catch (e, stackTrace) {
      _logger.warn(
        'Segment record already exists for did $did — keeping idempotent',
        error: e,
        stackTrace: stackTrace,
      );
    }
    return record;
  }

  Future<Map<String, dynamic>> resolveBySegment(String segment) async {
    final lookup = await _storage.findOneById<DidDocumentSegmentRecord>(
      DidDocumentSegmentRecord.entityName,
      segment,
      DidDocumentSegmentRecord.fromJson,
    );
    if (lookup == null) throw DidDocumentNotFound();

    final record = await _storage.findOneById<DidDocumentRecord>(
      DidDocumentRecord.entityName,
      lookup.did,
      DidDocumentRecord.fromJson,
    );
    if (record == null) throw DidDocumentNotFound();
    return record.didDocument;
  }

  Future<void> _verifyControlProof(
    String authDid,
    _DidDocumentProof controlProof,
  ) async {
    final authDidDocument = await _didResolver.resolveDid(authDid);
    final jwk = _findResolvedVerificationMethodJwk(
      authDidDocument,
      controlProof.verificationMethod,
    );
    if (jwk == null) {
      throw InvalidDidDocumentInput(
        'controlProof verificationMethod not found on authenticated DID',
      );
    }
    _verifyJws('controlProof', controlProof.jws, jwk);
  }

  void _verifyDidDocumentProof(
    Map<String, dynamic> didDocument,
    _DidDocumentProof proof,
  ) {
    final jwk = _findDidDocumentVerificationMethodJwk(
      didDocument,
      proof.verificationMethod,
    );
    if (jwk == null) {
      throw InvalidDidDocumentInput(
        'proof verificationMethod not found in didDocument',
      );
    }
    _verifyJws('proof', proof.jws, jwk);
  }

  Map<String, dynamic>? _findResolvedVerificationMethodJwk(
    DidDocument didDocument,
    String verificationMethodId,
  ) {
    for (final verificationMethod in didDocument.verificationMethod) {
      if (verificationMethod.id != verificationMethodId) {
        continue;
      }
      final publicKeyJwk = verificationMethod.toJson()['publicKeyJwk'];
      if (publicKeyJwk is Map) {
        return Map<String, dynamic>.from(publicKeyJwk);
      }
      return null;
    }
    return null;
  }

  Map<String, dynamic>? _findDidDocumentVerificationMethodJwk(
    Map<String, dynamic> didDocument,
    String verificationMethodId,
  ) {
    final rawMethods = didDocument['verificationMethod'];
    if (rawMethods is! List) {
      throw InvalidDidDocumentInput('DID Document has no verification methods');
    }
    for (final rawMethod in rawMethods) {
      if (rawMethod is! Map<String, dynamic>) {
        continue;
      }
      if (rawMethod['id'] != verificationMethodId) {
        continue;
      }
      final publicKeyJwk = rawMethod['publicKeyJwk'];
      if (publicKeyJwk is Map) {
        return Map<String, dynamic>.from(publicKeyJwk);
      }
      return null;
    }
    return null;
  }

  void _verifyJws(
    String fieldName,
    String jws,
    Map<String, dynamic> publicKeyJwk,
  ) {
    try {
      final key = JWTKey.fromJWK(publicKeyJwk);
      JWT.verify(jws, key);
    } catch (_) {
      throw InvalidDidDocumentInput('$fieldName JWS verification failed');
    }
  }

  String _extractAndValidateDid(Map<String, dynamic> didDocument) {
    final did = didDocument['id'];
    if (did is! String || did.trim().isEmpty) {
      throw InvalidDidDocumentInput(
        'didDocument.id must be a non-empty string',
      );
    }
    // Enforce exact shape: did:web:<host>:user:<segment>
    final parts = did.split(':');
    if (parts.length != 5 ||
        parts[0] != 'did' ||
        parts[1] != 'web' ||
        parts[3] != 'user') {
      throw InvalidDidDocumentInput(
        'didDocument.id must match did:web:<host>:user:<segment>',
      );
    }
    return did;
  }

  String _segmentFromDid(String did) {
    final segment = did.split(':').last.trim();
    if (segment.isEmpty) {
      throw InvalidDidDocumentInput('Invalid did:web segment');
    }
    return segment;
  }
}

class _DidDocumentProof {
  _DidDocumentProof({
    required this.type,
    required this.created,
    required this.verificationMethod,
    required this.proofPurpose,
    required this.jws,
  });

  factory _DidDocumentProof.fromJson(
    Map<String, dynamic> json, {
    required String fieldName,
  }) {
    final type = json['type'];
    final created = json['created'];
    final verificationMethod = json['verificationMethod'];
    final proofPurpose = json['proofPurpose'];
    final jws = json['jws'];
    if (type is! String ||
        created is! String ||
        verificationMethod is! String ||
        proofPurpose is! String ||
        jws is! String) {
      throw InvalidDidDocumentInput(
        '$fieldName must contain type, created, verificationMethod, '
        'proofPurpose, and jws',
      );
    }
    if (DateTime.tryParse(created) == null) {
      throw InvalidDidDocumentInput('$fieldName.created must be ISO-8601');
    }
    if (type != 'JsonWebSignature2020') {
      throw InvalidDidDocumentInput(
        '$fieldName.type must be JsonWebSignature2020',
      );
    }
    if (proofPurpose != 'authentication') {
      throw InvalidDidDocumentInput(
        '$fieldName.proofPurpose must be authentication',
      );
    }
    return _DidDocumentProof(
      type: type,
      created: created,
      verificationMethod: verificationMethod,
      proofPurpose: proofPurpose,
      jws: jws,
    );
  }

  final String type;
  final String created;
  final String verificationMethod;
  final String proofPurpose;
  final String jws;
}
