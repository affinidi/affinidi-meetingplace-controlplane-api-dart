import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../../../utils/date_time.dart';
import '../../../utils/jcs_serializer.dart';
import '../../entity/did_document_jti_record.dart';
import '../../entity/did_document_record.dart';
import '../../entity/did_document_segment_record.dart';
import '../../logger/logger.dart';
import '../../storage/exception/already_exists_exception.dart';
import '../../storage/storage.dart';
import 'did_document_proof_verifier.dart';

export 'did_document_proof_verifier.dart' show InvalidDidDocumentInput;

class DidDocumentNotFound implements Exception {}

class DidDocumentConflict implements Exception {
  DidDocumentConflict(this.message);
  final String message;
}

class DidDocumentService {
  DidDocumentService({
    required Storage storage,
    required DidResolver didResolver,
    required String proofAudience,
    required String hostedDidHost,
    required Logger logger,
  }) : _storage = storage,
       _proofAudience = proofAudience,
       _hostedDidHost = hostedDidHost,
       _logger = logger,
       _proofVerifier = DidDocumentProofVerifier(didResolver: didResolver);

  final Storage _storage;
  final String _proofAudience;
  final String _hostedDidHost;
  final Logger _logger;
  final DidDocumentProofVerifier _proofVerifier;

  Future<DidDocumentRecord> upload({
    required String authDid,
    required String authVerificationMethod,
    required Map<String, dynamic> didDocument,
    required Map<String, dynamic> controlProof,
    required Map<String, dynamic> proof,
  }) async {
    final did = _extractAndValidateDid(didDocument);
    final verifiedClaims = await _proofVerifier.verify(
      authDid: authDid,
      authVerificationMethod: authVerificationMethod,
      didDocument: didDocument,
      controlProofJson: controlProof,
      proofJson: proof,
      proofAudience: _proofAudience,
    );
    final reservedJti = await _reserveJti(
      did: did,
      verifiedClaims: verifiedClaims,
    );

    var accepted = false;
    try {
      final record = await _storeDidDocument(
        did: did,
        authDid: authDid,
        authVerificationMethod: authVerificationMethod,
        didDocument: didDocument,
      );
      accepted = true;
      return record;
    } finally {
      if (!accepted) {
        await _releaseReservedJti(reservedJti);
      }
    }
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

  Future<DidDocumentRecord> _storeDidDocument({
    required String did,
    required String authDid,
    required String authVerificationMethod,
    required Map<String, dynamic> didDocument,
  }) async {
    final segment = _segmentFromDid(did);
    final now = nowUtc();

    final existing = await _storage.findOneById<DidDocumentRecord>(
      DidDocumentRecord.entityName,
      did,
      DidDocumentRecord.fromJson,
    );
    if (existing != null) {
      return _handleExistingRecord(
        existing,
        authDid: authDid,
        authVerificationMethod: authVerificationMethod,
        didDocument: didDocument,
      );
    }

    final record = DidDocumentRecord(
      did: did,
      createdBy: authDid,
      createdByVerificationMethod: authVerificationMethod,
      createdAt: now,
      updatedAt: now,
      didDocument: didDocument,
    );

    try {
      await _storage.create(record);
    } on AlreadyExists {
      final concurrentRecord = await _storage.findOneById<DidDocumentRecord>(
        DidDocumentRecord.entityName,
        did,
        DidDocumentRecord.fromJson,
      );
      if (concurrentRecord == null) {
        throw DidDocumentConflict('DID already registered');
      }
      return _handleExistingRecord(
        concurrentRecord,
        authDid: authDid,
        authVerificationMethod: authVerificationMethod,
        didDocument: didDocument,
      );
    }

    try {
      await _storage.create(
        DidDocumentSegmentRecord(segment: segment, did: did),
      );
    } on AlreadyExists {
      final segmentRecord = await _storage
          .findOneById<DidDocumentSegmentRecord>(
            DidDocumentSegmentRecord.entityName,
            segment,
            DidDocumentSegmentRecord.fromJson,
          );
      if (segmentRecord?.did == did) {
        return record;
      }
      await _storage.delete(DidDocumentRecord.entityName, did);
      throw DidDocumentConflict('Segment already claimed by another DID');
    }
    return record;
  }

  Future<DidDocumentRecord> _handleExistingRecord(
    DidDocumentRecord existing, {
    required String authDid,
    required String authVerificationMethod,
    required Map<String, dynamic> didDocument,
  }) async {
    if (existing.createdBy != authDid) {
      _logger.warn(
        'Rejected did document retry for ${existing.did}: authenticated DID '
        'does not match the stored owner',
      );
      throw DidDocumentConflict('DID already registered by another user');
    }
    if (existing.createdByVerificationMethod != authVerificationMethod) {
      _logger.warn(
        'Rejected did document retry for ${existing.did}: authenticated key '
        'does not match the stored owner key',
      );
      throw DidDocumentConflict(
        'DID already registered by another authenticated key',
      );
    }
    if (jcsSerializer.serializeObject(existing.didDocument) !=
        jcsSerializer.serializeObject(didDocument)) {
      throw DidDocumentConflict(
        'DID already registered with a different document',
      );
    }
    final segment = _segmentFromDid(existing.did);
    try {
      await _storage.create(
        DidDocumentSegmentRecord(segment: segment, did: existing.did),
      );
    } on AlreadyExists {
      final segmentRecord = await _storage
          .findOneById<DidDocumentSegmentRecord>(
            DidDocumentSegmentRecord.entityName,
            segment,
            DidDocumentSegmentRecord.fromJson,
          );
      if (segmentRecord?.did != existing.did) {
        throw DidDocumentConflict('Segment already claimed by another DID');
      }
    }
    return existing;
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
    final hostedDidHost = _decodeDidWebHost(parts[2]);
    if (hostedDidHost.toLowerCase() != _hostedDidHost.toLowerCase()) {
      throw InvalidDidDocumentInput(
        'didDocument.id host must match $_hostedDidHost',
      );
    }
    final segment = parts[4].trim();
    if (!Uuid.isValidUUID(fromString: segment)) {
      throw InvalidDidDocumentInput('didDocument.id segment must be a UUID');
    }
    return did;
  }

  String _decodeDidWebHost(String host) {
    try {
      return Uri.decodeComponent(host);
    } on FormatException {
      throw InvalidDidDocumentInput('didDocument.id host is not valid');
    }
  }

  String _segmentFromDid(String did) {
    final segment = did.split(':').last.trim();
    if (segment.isEmpty) {
      throw InvalidDidDocumentInput('Invalid did:web segment');
    }
    return segment;
  }

  Future<DidDocumentJtiRecord> _reserveJti({
    required String did,
    required DidDocumentVerifiedProofClaims verifiedClaims,
  }) async {
    final record = DidDocumentJtiRecord(
      did: did,
      jti: verifiedClaims.jti,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        verifiedClaims.exp * 1000,
        isUtc: true,
      ),
      proofPurpose: verifiedClaims.proofPurpose,
      operation: verifiedClaims.operation,
    );

    final existing = await _storage.findOneById<DidDocumentJtiRecord>(
      DidDocumentJtiRecord.entityName,
      record.getId(),
      DidDocumentJtiRecord.fromJson,
    );
    if (existing != null) {
      if (!existing.expiresAt.isBefore(nowUtc())) {
        throw DidDocumentConflict('Proof JTI has already been used');
      }
      await _storage.delete(DidDocumentJtiRecord.entityName, record.getId());
    }

    try {
      await _storage.create(record);
    } on AlreadyExists {
      throw DidDocumentConflict('Proof JTI has already been used');
    }

    return record;
  }

  Future<void> _releaseReservedJti(DidDocumentJtiRecord record) {
    return _storage.delete(DidDocumentJtiRecord.entityName, record.getId());
  }
}
