import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
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
       _didResolver = didResolver,
       _proofAudience = proofAudience,
       _hostedDidHost = hostedDidHost,
       _logger = logger;

  final Storage _storage;
  final DidResolver _didResolver;
  final String _proofAudience;
  final String _hostedDidHost;
  final Logger _logger;

  Future<DidDocumentRecord> upload({
    required String authDid,
    required String authVerificationMethod,
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
    final proofPayload = _buildExpectedProofPayloadFields(
      authDid: authDid,
      didDocument: didDocument,
    );
    await _verifyControlProof(
      authDid,
      authVerificationMethod,
      parsedControlProof,
      proofPayload,
    );
    await _verifyDidDocumentProof(didDocument, parsedProof, proofPayload);
    final segment = _segmentFromDid(did);
    final now = DateTime.now().toUtc();

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
    String authVerificationMethod,
    _DidDocumentProof controlProof,
    Map<String, dynamic> expectedPayload,
  ) async {
    if (authVerificationMethod.isEmpty) {
      throw InvalidDidDocumentInput(
        'Authenticated verification method is required',
      );
    }
    if (controlProof.verificationMethod != authVerificationMethod) {
      throw InvalidDidDocumentInput(
        'controlProof verificationMethod must match the authenticated key',
      );
    }
    final authDidDocument = await _didResolver.resolveDid(authDid);
    if (!_containsResolvedVerificationMethod(
      authDidDocument,
      authVerificationMethod,
    )) {
      throw InvalidDidDocumentInput(
        'controlProof verificationMethod not found on authenticated DID',
      );
    }
    await _verifyProofJws(
      fieldName: 'controlProof',
      jws: controlProof.jws,
      verificationMethod: authVerificationMethod,
      expectedPayload: expectedPayload,
      verifier: await DidVerifier.create(
        algorithm: _signatureSchemeForJws(controlProof.jws),
        issuerDid: authDid,
        kid: authVerificationMethod,
        didResolver: _didResolver,
      ),
    );
  }

  Future<void> _verifyDidDocumentProof(
    Map<String, dynamic> didDocument,
    _DidDocumentProof proof,
    Map<String, dynamic> expectedPayload,
  ) async {
    if (!_isAuthenticationMethod(didDocument, proof.verificationMethod)) {
      throw InvalidDidDocumentInput(
        'proof verificationMethod must be listed in didDocument.authentication',
      );
    }
    if (!_containsDidDocumentVerificationMethod(
      didDocument,
      proof.verificationMethod,
    )) {
      throw InvalidDidDocumentInput(
        'proof verificationMethod not found in didDocument',
      );
    }
    await _verifyProofJws(
      fieldName: 'proof',
      jws: proof.jws,
      verificationMethod: proof.verificationMethod,
      expectedPayload: expectedPayload,
      verifier: await DidVerifier.create(
        algorithm: _signatureSchemeForJws(proof.jws),
        issuerDid: didDocument['id'] as String,
        kid: proof.verificationMethod,
        didResolver: _InlineDidResolver(didDocument),
      ),
    );
  }

  bool _containsResolvedVerificationMethod(
    DidDocument didDocument,
    String verificationMethodId,
  ) {
    for (final verificationMethod in didDocument.verificationMethod) {
      if (verificationMethod.id == verificationMethodId) {
        return true;
      }
    }
    return false;
  }

  bool _containsDidDocumentVerificationMethod(
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
      if (rawMethod['id'] == verificationMethodId) {
        return true;
      }
    }
    return false;
  }

  Future<void> _verifyProofJws({
    required String fieldName,
    required String jws,
    required String verificationMethod,
    required Map<String, dynamic> expectedPayload,
    required DidVerifier verifier,
  }) async {
    final parsedJws = _parseJws(fieldName, jws);
    final headerKid = parsedJws.header['kid'];
    if (headerKid is String &&
        headerKid.isNotEmpty &&
        headerKid != verificationMethod) {
      throw InvalidDidDocumentInput(
        '$fieldName JWS kid must match $verificationMethod',
      );
    }
    final expectedPayloadWithClaims = {
      ...expectedPayload,
      'iat': parsedJws.payload['iat'],
      'exp': parsedJws.payload['exp'],
      'jti': parsedJws.payload['jti'],
    };
    if (_canonicalizeJson(parsedJws.payload) !=
        _canonicalizeJson(expectedPayloadWithClaims)) {
      throw InvalidDidDocumentInput(
        '$fieldName payload does not match the upload request',
      );
    }
    if (!verifier.verify(parsedJws.signingInput, parsedJws.signature)) {
      throw InvalidDidDocumentInput('$fieldName JWS verification failed');
    }
  }

  _ParsedJws _parseJws(String fieldName, String jws) {
    final parts = jws.split('.');
    if (parts.length != 3 || parts[1].isEmpty) {
      throw InvalidDidDocumentInput(
        '$fieldName.jws must be a compact JWS with an embedded payload',
      );
    }
    try {
      final header = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[0]))),
      );
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (header is! Map<String, dynamic> || payload is! Map<String, dynamic>) {
        throw InvalidDidDocumentInput(
          '$fieldName.jws must contain JSON header and payload objects',
        );
      }
      _validateProofPayload(fieldName, payload);
      return _ParsedJws(
        header: header,
        payload: payload,
        signingInput: Uint8List.fromList(
          utf8.encode('${parts[0]}.${parts[1]}'),
        ),
        signature: Uint8List.fromList(
          base64Url.decode(base64Url.normalize(parts[2])),
        ),
      );
    } on FormatException {
      throw InvalidDidDocumentInput('$fieldName.jws must be valid base64url');
    }
  }

  void _validateProofPayload(String fieldName, Map<String, dynamic> payload) {
    final operation = payload['operation'];
    final didDocumentId = payload['didDocumentId'];
    final didDocumentHash = payload['didDocumentHash'];
    final controlDid = payload['controlDid'];
    final aud = payload['aud'];
    final iat = payload['iat'];
    final exp = payload['exp'];
    final jti = payload['jti'];
    if (operation is! String ||
        didDocumentId is! String ||
        didDocumentHash is! String ||
        controlDid is! String ||
        aud is! String ||
        iat is! int ||
        exp is! int ||
        jti is! String ||
        jti.isEmpty ||
        exp <= iat) {
      throw InvalidDidDocumentInput(
        '$fieldName payload must contain operation, didDocumentId, '
        'didDocumentHash, controlDid, aud, iat, exp, and jti',
      );
    }
  }

  SignatureScheme _signatureSchemeForJws(String jws) {
    final parts = jws.split('.');
    if (parts.length != 3) {
      throw InvalidDidDocumentInput('JWS must use compact serialization');
    }
    try {
      final header = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[0]))),
      );
      if (header is! Map<String, dynamic>) {
        throw InvalidDidDocumentInput('JWS header must be a JSON object');
      }
      final alg = header['alg'];
      if (alg is! String) {
        throw InvalidDidDocumentInput('JWS header must contain alg');
      }
      return SignatureScheme.fromAlg(alg);
    } catch (_) {
      throw InvalidDidDocumentInput('JWS header must contain a supported alg');
    }
  }

  Map<String, dynamic> _buildExpectedProofPayloadFields({
    required String authDid,
    required Map<String, dynamic> didDocument,
  }) {
    final canonicalDidDocument = utf8.encode(_canonicalizeJson(didDocument));
    final didDocumentHash = base64Url
        .encode(sha256.convert(canonicalDidDocument).bytes)
        .replaceAll('=', '');
    return {
      'operation': 'did-document/upload',
      'didDocumentId': didDocument['id'],
      'didDocumentHash': didDocumentHash,
      'controlDid': authDid,
      'aud': _proofAudience,
    };
  }

  bool _isAuthenticationMethod(
    Map<String, dynamic> didDocument,
    String verificationMethodId,
  ) {
    final authentication = didDocument['authentication'];
    if (authentication is! List) {
      throw InvalidDidDocumentInput(
        'DID Document authentication must be a list',
      );
    }
    return authentication.contains(verificationMethodId);
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
    if (_canonicalizeJson(existing.didDocument) !=
        _canonicalizeJson(didDocument)) {
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

  String _canonicalizeJson(Object? value) {
    if (value is Map) {
      final entries = value.entries.toList()
        ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
      return '{${entries.map((entry) => '${jsonEncode(entry.key.toString())}:${_canonicalizeJson(entry.value)}').join(',')}}';
    }
    if (value is List) {
      return '[${value.map(_canonicalizeJson).join(',')}]';
    }
    return jsonEncode(value);
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
    if (parts[2].toLowerCase() != _hostedDidHost.toLowerCase()) {
      throw InvalidDidDocumentInput(
        'didDocument.id host must match $_hostedDidHost',
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

class _ParsedJws {
  _ParsedJws({
    required this.header,
    required this.payload,
    required this.signingInput,
    required this.signature,
  });

  final Map<String, dynamic> header;
  final Map<String, dynamic> payload;
  final Uint8List signingInput;
  final Uint8List signature;
}

class _InlineDidResolver implements DidResolver {
  _InlineDidResolver(this._didDocumentJson);

  final Map<String, dynamic> _didDocumentJson;

  @override
  Future<DidDocument> resolveDid(String did) async {
    return DidDocument.fromJson(_didDocumentJson);
  }
}
