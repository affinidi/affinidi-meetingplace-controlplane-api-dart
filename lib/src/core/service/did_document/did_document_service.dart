import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

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
  DidDocumentService({required Storage storage, required Logger logger})
    : _storage = storage,
      _logger = logger;

  final Storage _storage;
  final Logger _logger;

  Future<DidDocumentRecord> upload({
    required String authDid,
    required Map<String, dynamic> didDocument,
    required String controlProof,
    required String proof,
  }) async {
    final did = _extractAndValidateDid(didDocument);
    _verifyJws(didDocument, controlProof);
    _verifyJws(didDocument, proof);
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

  void _verifyJws(Map<String, dynamic> didDocument, String jws) {
    final rawMethods =
        (didDocument['verificationMethod'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        [];
    if (rawMethods.isEmpty) {
      throw InvalidDidDocumentInput('DID Document has no verification methods');
    }
    for (final vm in rawMethods) {
      final pkJwk = vm['publicKeyJwk'] as Map<String, dynamic>?;
      if (pkJwk == null) continue;
      try {
        final key = JWTKey.fromJWK(Map<String, dynamic>.from(pkJwk));
        JWT.verify(jws, key);
        return;
      } catch (_) {
        continue;
      }
    }
    throw InvalidDidDocumentInput('DID Document proof verification failed');
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
