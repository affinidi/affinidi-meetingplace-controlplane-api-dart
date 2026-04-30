import '../../entity/did_document_record.dart';
import '../../entity/did_document_segment_record.dart';
import '../../storage/exception/already_exists_exception.dart';
import '../../storage/storage.dart';

class DidDocumentNotFound implements Exception {}

class InvalidDidDocumentInput implements Exception {
  InvalidDidDocumentInput(this.message);
  final String message;
}

class DidDocumentService {
  DidDocumentService({required Storage storage}) : _storage = storage;

  final Storage _storage;

  Future<DidDocumentRecord> upload({
    required String authDid,
    required Map<String, dynamic> didDocument,
  }) async {
    final did = _extractAndValidateDid(didDocument);
    final segment = _segmentFromDid(did);
    final now = DateTime.now().toUtc();

    final existing = await _storage.findOneById<DidDocumentRecord>(
      'DidDocument',
      did,
      DidDocumentRecord.fromJson,
    );
    if (existing != null) return existing;

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
    } on AlreadyExists {
      // keep idempotent behavior
    }
    return record;
  }

  Future<DidDocumentRecord> update({
    required String authDid,
    required Map<String, dynamic> didDocument,
  }) async {
    final did = _extractAndValidateDid(didDocument);
    final existing = await _storage.findOneById<DidDocumentRecord>(
      'DidDocument',
      did,
      DidDocumentRecord.fromJson,
    );
    if (existing == null) throw DidDocumentNotFound();
    if (existing.createdBy != authDid) {
      throw InvalidDidDocumentInput(
        'Authenticated DID does not own this DID document',
      );
    }

    final updated = DidDocumentRecord(
      did: existing.did,
      createdBy: existing.createdBy,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now().toUtc(),
      didDocument: didDocument,
    );
    return _storage.update(updated);
  }

  Future<Map<String, dynamic>> resolveBySegment(String segment) async {
    final lookup = await _storage.findOneById<DidDocumentSegmentRecord>(
      'DidDocumentSegment',
      segment,
      DidDocumentSegmentRecord.fromJson,
    );
    if (lookup == null) throw DidDocumentNotFound();

    final record = await _storage.findOneById<DidDocumentRecord>(
      'DidDocument',
      lookup.did,
      DidDocumentRecord.fromJson,
    );
    if (record == null) throw DidDocumentNotFound();
    return record.didDocument;
  }

  String _extractAndValidateDid(Map<String, dynamic> didDocument) {
    final did = didDocument['id'];
    if (did is! String || did.trim().isEmpty) {
      throw InvalidDidDocumentInput('didDocument.id must be a non-empty string');
    }
    if (!did.startsWith('did:web:')) {
      throw InvalidDidDocumentInput('didDocument.id must use did:web');
    }
    if (!did.contains(':user:')) {
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
