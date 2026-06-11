import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:meeting_place_control_plane_api/src/utils/jcs_serializer.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

Map<String, dynamic> buildDidWebDocument({
  required String host,
  required Map<String, dynamic> publicKeyJwk,
  String? segment,
}) {
  segment ??= const Uuid().v4();
  final encodedHost = Uri.encodeComponent(host);
  final did = 'did:web:$encodedHost:user:$segment';
  return {
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
}

Map<String, dynamic> buildProofPayload({
  required Map<String, dynamic> didDocument,
  required String controlDid,
  required String audience,
  int? iat,
  int? exp,
  String? jti,
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
    'controlDid': controlDid,
    'aud': audience,
    'iat': issuedAt,
    'exp': expiresAt,
    'jti': jti ?? const Uuid().v4(),
  };
}

Future<String> signProof({
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

Future<Map<String, dynamic>> buildSignedProof({
  required PersistentWallet wallet,
  required String keyId,
  required String verificationMethod,
  required Map<String, dynamic> payload,
  String type = 'JsonWebSignature2020',
  String proofPurpose = 'authentication',
}) async {
  return {
    'type': type,
    'created': DateTime.now().toUtc().toIso8601String(),
    'verificationMethod': verificationMethod,
    'proofPurpose': proofPurpose,
    'jws': await signProof(
      wallet: wallet,
      keyId: keyId,
      verificationMethod: verificationMethod,
      payload: payload,
    ),
  };
}

Future<({Map<String, dynamic> controlProof, Map<String, dynamic> proof})>
buildUploadProofs({
  required PersistentWallet authWallet,
  required String authKeyId,
  required String authVerificationMethod,
  required PersistentWallet didWallet,
  required String didKeyId,
  required Map<String, dynamic> didDocument,
  required String controlDid,
  required String audience,
  int? iat,
  int? exp,
  String? jti,
}) async {
  final payload = buildProofPayload(
    didDocument: didDocument,
    controlDid: controlDid,
    audience: audience,
    iat: iat,
    exp: exp,
    jti: jti,
  );
  return (
    controlProof: await buildSignedProof(
      wallet: authWallet,
      keyId: authKeyId,
      verificationMethod: authVerificationMethod,
      payload: payload,
    ),
    proof: await buildSignedProof(
      wallet: didWallet,
      keyId: didKeyId,
      verificationMethod: '${didDocument['id']}#key-1',
      payload: payload,
    ),
  );
}
