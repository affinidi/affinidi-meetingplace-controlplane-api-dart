import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:ssi/ssi.dart';

import '../../../utils/date_time.dart';
import '../../../utils/jcs_serializer.dart';

class InvalidDidDocumentInput implements Exception {
  InvalidDidDocumentInput(this.message);
  final String message;
}

/// Holds the verified proof claims returned by [DidDocumentProofVerifier].
class DidDocumentVerifiedProofClaims {
  DidDocumentVerifiedProofClaims({
    required this.jti,
    required this.exp,
    required this.operation,
    required this.proofPurpose,
  });

  final String jti;
  final int exp;
  final String operation;
  final String proofPurpose;
}

/// Verifies the dual-JWS ownership proof attached to a DID document upload.
///
/// Validates both the [controlProof] (signed by the authenticated caller's
/// key) and the [proof] (signed by a key listed in the DID document itself),
/// confirms their payloads match, and returns the verified claims.
class DidDocumentProofVerifier {
  DidDocumentProofVerifier({
    required DidResolver didResolver,
    int maxProofWindowSeconds = 300,
  }) : _didResolver = didResolver,
       _maxProofWindowSeconds = maxProofWindowSeconds;

  final DidResolver _didResolver;
  final int _maxProofWindowSeconds;

  Future<DidDocumentVerifiedProofClaims> verify({
    required String authDid,
    required String authVerificationMethod,
    required Map<String, dynamic> didDocument,
    required Map<String, dynamic> controlProofJson,
    required Map<String, dynamic> proofJson,
    required String proofAudience,
  }) async {
    final parsedControlProof = _DidDocumentProof.fromJson(
      controlProofJson,
      fieldName: 'controlProof',
    );
    final parsedProof = _DidDocumentProof.fromJson(
      proofJson,
      fieldName: 'proof',
    );
    final proofPayload = _buildExpectedPayloadFields(
      authDid: authDid,
      didDocument: didDocument,
      proofAudience: proofAudience,
    );

    final parsedControlJws = await _verifyControlProof(
      authDid,
      authVerificationMethod,
      parsedControlProof,
      proofPayload,
    );
    final parsedDidDocumentJws = await _verifyDidDocumentProof(
      didDocument,
      parsedProof,
      proofPayload,
    );
    final sharedClaims = _validateSharedProofClaims(
      parsedControlJws,
      parsedDidDocumentJws,
    );

    return DidDocumentVerifiedProofClaims(
      jti: sharedClaims.jti,
      exp: sharedClaims.exp,
      operation: sharedClaims.operation,
      proofPurpose: parsedProof.proofPurpose,
    );
  }

  Future<_ParsedJws> _verifyControlProof(
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
    return _verifyProofJws(
      fieldName: 'controlProof',
      jws: controlProof.jws,
      verificationMethod: authVerificationMethod,
      expectedPayload: expectedPayload,
      verifier: await DidVerifier.create(
        algorithm: _JwsParser.signatureScheme(controlProof.jws),
        issuerDid: authDid,
        kid: authVerificationMethod,
        didResolver: _didResolver,
      ),
    );
  }

  Future<_ParsedJws> _verifyDidDocumentProof(
    Map<String, dynamic> didDocument,
    _DidDocumentProof proof,
    Map<String, dynamic> expectedPayload,
  ) async {
    final documentId = didDocument['id'];
    if (documentId is! String || documentId.isEmpty) {
      throw InvalidDidDocumentInput(
        'didDocument.id must be a non-empty string',
      );
    }
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
    return _verifyProofJws(
      fieldName: 'proof',
      jws: proof.jws,
      verificationMethod: proof.verificationMethod,
      expectedPayload: expectedPayload,
      verifier: await DidVerifier.create(
        algorithm: _JwsParser.signatureScheme(proof.jws),
        issuerDid: documentId,
        kid: proof.verificationMethod,
        didResolver: _InlineDidResolver(
          _normalizeDidDocumentForInlineResolution(didDocument),
        ),
      ),
    );
  }

  _ParsedJws _verifyProofJws({
    required String fieldName,
    required String jws,
    required String verificationMethod,
    required Map<String, dynamic> expectedPayload,
    required DidVerifier verifier,
  }) {
    final parsedJws = _JwsParser.parse(fieldName, jws);
    _validateProofPayload(fieldName, parsedJws.payload);
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
    if (jcsSerializer.serialize(parsedJws.payload) !=
        jcsSerializer.serialize(expectedPayloadWithClaims)) {
      throw InvalidDidDocumentInput(
        '$fieldName payload does not match the upload request',
      );
    }
    if (!verifier.verify(parsedJws.signingInput, parsedJws.signature)) {
      throw InvalidDidDocumentInput('$fieldName JWS verification failed');
    }
    return parsedJws;
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
    if (exp - iat > _maxProofWindowSeconds) {
      throw InvalidDidDocumentInput(
        '$fieldName proof window exceeds maximum allowed duration',
      );
    }
    final nowEpoch = nowUtc().millisecondsSinceEpoch ~/ 1000;
    if (exp <= nowEpoch) {
      throw InvalidDidDocumentInput('$fieldName proof has expired');
    }
    if (iat > nowEpoch) {
      throw InvalidDidDocumentInput('$fieldName proof iat is in the future');
    }
  }

  static const String _uploadOperation = 'did-document/upload';

  Map<String, dynamic> _buildExpectedPayloadFields({
    required String authDid,
    required Map<String, dynamic> didDocument,
    required String proofAudience,
  }) {
    final canonicalDidDocument = jcsSerializer.serializeObjectToUtf8(
      didDocument,
    );
    final didDocumentHash = base64Url
        .encode(sha256.convert(canonicalDidDocument).bytes)
        .replaceAll('=', '');
    return {
      'operation': _uploadOperation,
      'didDocumentId': didDocument['id'],
      'didDocumentHash': didDocumentHash,
      'controlDid': authDid,
      'aud': proofAudience,
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
    for (final entry in authentication) {
      if (entry == verificationMethodId) {
        return true;
      }
      if (entry is Map<String, dynamic> &&
          entry['id'] == verificationMethodId) {
        return true;
      }
    }
    return false;
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
    if (rawMethods is List) {
      for (final rawMethod in rawMethods) {
        if (rawMethod is Map<String, dynamic> &&
            rawMethod['id'] == verificationMethodId) {
          return true;
        }
      }
    }

    // Also accept verification methods embedded directly in authentication.
    final authentication = didDocument['authentication'];
    if (authentication is List) {
      for (final entry in authentication) {
        if (entry is Map<String, dynamic> &&
            entry['id'] == verificationMethodId) {
          return true;
        }
      }
    }

    if (rawMethods is! List && authentication is! List) {
      throw InvalidDidDocumentInput('DID Document has no verification methods');
    }

    return false;
  }

  Map<String, dynamic> _normalizeDidDocumentForInlineResolution(
    Map<String, dynamic> didDocument,
  ) {
    final normalizedDidDocument = Map<String, dynamic>.from(didDocument);
    final mergedVerificationMethods = <Map<String, dynamic>>[];
    final seenVerificationMethodIds = <String>{};

    void addVerificationMethod(dynamic candidate) {
      if (candidate is! Map) {
        return;
      }

      final method = Map<String, dynamic>.from(candidate);
      final id = method['id'];
      if (id is! String || id.isEmpty || !seenVerificationMethodIds.add(id)) {
        return;
      }

      mergedVerificationMethods.add(method);
    }

    final rawMethods = didDocument['verificationMethod'];
    if (rawMethods is List) {
      for (final rawMethod in rawMethods) {
        addVerificationMethod(rawMethod);
      }
    }

    final authentication = didDocument['authentication'];
    if (authentication is List) {
      for (final entry in authentication) {
        addVerificationMethod(entry);
      }
    }

    if (mergedVerificationMethods.isNotEmpty) {
      normalizedDidDocument['verificationMethod'] = mergedVerificationMethods;
    }

    return normalizedDidDocument;
  }

  _DidDocumentProofClaims _validateSharedProofClaims(
    _ParsedJws controlProof,
    _ParsedJws didDocumentProof,
  ) {
    final controlPayloadWithoutJti = Map<String, dynamic>.from(
      controlProof.payload,
    )..remove('jti');
    final docProofPayloadWithoutJti = Map<String, dynamic>.from(
      didDocumentProof.payload,
    )..remove('jti');

    if (jcsSerializer.serialize(controlPayloadWithoutJti) !=
        jcsSerializer.serialize(docProofPayloadWithoutJti)) {
      throw InvalidDidDocumentInput(
        'controlProof and proof must use the same proof payload',
      );
    }
    return _DidDocumentProofClaims.fromPayload(controlProof.payload);
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

class _DidDocumentProofClaims {
  _DidDocumentProofClaims({
    required this.operation,
    required this.exp,
    required this.jti,
  });

  factory _DidDocumentProofClaims.fromPayload(Map<String, dynamic> payload) {
    return _DidDocumentProofClaims(
      operation: payload['operation'] as String,
      exp: payload['exp'] as int,
      jti: payload['jti'] as String,
    );
  }

  final String operation;
  final int exp;
  final String jti;
}

class _InlineDidResolver implements DidResolver {
  _InlineDidResolver(this._didDocumentJson);

  final Map<String, dynamic> _didDocumentJson;

  @override
  Future<DidDocument> resolveDid(String did) async {
    final documentId = _didDocumentJson['id'];
    if (documentId != did) {
      throw InvalidDidDocumentInput(
        'DID does not match the inline document id',
      );
    }
    return DidDocument.fromJson(_didDocumentJson);
  }
}

/// Handles compact JWS structural parsing: base64url decoding, JSON decoding,
/// and algorithm extraction. Domain-level payload validation is the caller's
/// responsibility.
class _JwsParser {
  static SignatureScheme signatureScheme(String jws) {
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
    } on FormatException {
      throw InvalidDidDocumentInput('JWS header must be valid base64url JSON');
    } on ArgumentError {
      throw InvalidDidDocumentInput('JWS header must contain a supported alg');
    }
  }

  static _ParsedJws parse(String fieldName, String jws) {
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
}
