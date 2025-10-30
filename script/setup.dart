import 'dart:io';
import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart';
import 'package:meeting_place_control_plane_api/src/core/config/env_config.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:cryptography/helpers.dart';

// KEY creation locally:
//
// openssl ecparam -name secp256k1 -genkey -noout -out ./keys/secp256k1.pem
// openssl ecparam -name prime256v1 -genkey -noout -out ./keys/p256.pem

// openssl genpkey -algorithm Ed25519 -out ./keys/ed25519.pem
// openssl pkey -in keys/ed25519.pem -pubout -out ./keys/ed25519-pub.pem

void main() async {
  final didWeb = getEnv('CONTROL_PLANE_DID');
  final serviceEndpoint = '${getEnv('API_ENDPOINT')}/v1';

  final p256Jwk = createJwkFromPrivateKey(
    pemPath: './keys/p256.pem',
    crv: 'P-256',
    domainParam: 'prime256v1',
    encode: base64url,
  );

  final secp256k1Jwk = createJwkFromPrivateKey(
    pemPath: './keys/secp256k1.pem',
    crv: 'secp256k1',
    domainParam: 'secp256k1',
    encode: (BigInt val) => base64UrlEncode(_encodeBigIntPadded(val, 32)),
  );

  final ed25519Jwk = await generateEd25519Jwk();
  final jwks = <Map<String, dynamic>>[p256Jwk, secp256k1Jwk, ed25519Jwk];

  final privateJwks = createPrivateJwks(jwks, didWeb);
  final publicJwks = createPublicJwks(jwks, didWeb);

  final didWebDocument = generateDidDocument(
    jwks: publicJwks,
    didWeb: didWeb,
    serviceEndpoint: serviceEndpoint,
  );

  final didDocumentFile = File('./params/did_document.json');
  final didcommAuthFile = File('./secrets/didcommauth.json');
  final hashSecretFile = File('./secrets/hash_secret.json');

  final directory = didDocumentFile.parent;
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  final secretsDirectory = didcommAuthFile.parent;
  if (!await secretsDirectory.exists()) {
    await secretsDirectory.create(recursive: true);
  }

  didDocumentFile.writeAsStringSync(jsonEncode(didWebDocument));
  didcommAuthFile.writeAsStringSync(jsonEncode([...privateJwks]));
  hashSecretFile.writeAsStringSync(jsonEncode({
    'secret': hex.encode(randomBytes(32)),
  }));
}

Map<String, dynamic> generateDidDocument({
  required List<Map<String, dynamic>> jwks,
  required String didWeb,
  required String serviceEndpoint,
}) {
  return {
    "@context": [
      "https://www.w3.org/ns/did/v1",
      {
        "publicKeyJwk": {
          "@id": "https://w3id.org/security#publicKeyJwk",
          "@type": "@json"
        }
      }
    ],
    "id": didWeb,
    "verificationMethod": jwks,
    "authentication": jwks.map((vm) => vm['id']).toList(),
    "assertionMethod": jwks.map((vm) => vm['id']).toList(),
    "keyAgreement": jwks.map((vm) => vm['id']).toList(),
    "service": [
      {
        "id": "$didWeb#auth",
        "type": "Authentication",
        "serviceEndpoint": "$serviceEndpoint/authenticate"
      },
      {
        "id": "$didWeb#api",
        "type": "RestAPI",
        "serviceEndpoint": serviceEndpoint
      }
    ]
  };
}

List<Map<String, dynamic>> createPrivateJwks(
  List<Map<String, dynamic>> jwks,
  String didWeb,
) {
  final privateVerificationMethod = <Map<String, dynamic>>[];
  for (final jwk in jwks.asMap().entries) {
    privateVerificationMethod.add({
      "id": "$didWeb#${jwk.key + 1}",
      "type": "JsonWebKey2020",
      "controller": didWeb,
      "privateKeyJwk": {
        'kid': "$didWeb#${jwk.key + 1}",
        'kty': jwk.value['kty'],
        'crv': jwk.value['crv'],
        'x': jwk.value['x'],
        if (jwk.value['y'] != null) 'y': jwk.value['y'],
        'd': jwk.value['d'],
      }
    });
  }

  return privateVerificationMethod;
}

List<Map<String, dynamic>> createPublicJwks(
  List<Map<String, dynamic>> jwks,
  String didWeb,
) {
  final verificationMethod = <Map<String, dynamic>>[];
  for (final jwk in jwks.asMap().entries) {
    verificationMethod.add({
      "id": "$didWeb#${jwk.key + 1}",
      "type": "JsonWebKey2020",
      "controller": didWeb,
      "publicKeyJwk": {
        'kty': jwk.value['kty'],
        'crv': jwk.value['crv'],
        'x': jwk.value['x'],
        if (jwk.value['y'] != null) 'y': jwk.value['y'],
      },
    });
  }

  return verificationMethod;
}

createJwkFromPrivateKey({
  required String pemPath,
  required String crv,
  required String domainParam,
  required dynamic encode,
}) {
  final ecPrivateKey = CryptoUtils.ecPrivateKeyFromPem(
    File(pemPath).readAsStringSync(),
  );

  final params = ECDomainParameters(domainParam);
  final Q = params.G * ecPrivateKey.d;

  return {
    'kty': 'EC',
    'crv': crv,
    'x': removeBase64TrailingPadding(encode(Q!.x!.toBigInteger()!)),
    'y': removeBase64TrailingPadding(encode(Q.y!.toBigInteger()!)),
    'd': removeBase64TrailingPadding(encode(ecPrivateKey.d!)),
  };
}

/// Helper: Strip leading 0 if present
List<int> _stripLeadingZero(List<int> bytes) {
  return (bytes.isNotEmpty && bytes.first == 0x00) ? bytes.sublist(1) : bytes;
}

/// Helper: Encode BigInt to unsigned byte list
List<int> _encodeBigIntUnsigned(BigInt number) {
  final bytes = <int>[];
  var temp = number;

  while (temp > BigInt.zero) {
    bytes.insert(0, (temp & BigInt.from(0xff)).toInt());
    temp >>= 8;
  }

  return bytes;
}

String removeBase64TrailingPadding(String base64) {
  return base64.replaceFirst(RegExp(r'=+$'), '');
}

/// Helper: Pad bytes to fixed length
List<int> _encodeBigIntPadded(BigInt number, int length) {
  final bytes = _encodeBigIntUnsigned(number);
  if (bytes.length > length) {
    throw ArgumentError('Value too large for $length-byte field');
  }
  return List.filled(length - bytes.length, 0) + bytes;
}

String base64url(BigInt val) =>
    base64UrlEncode(_stripLeadingZero(_encodeBigIntUnsigned(val)));

Future<Map<String, dynamic>> generateEd25519Jwk(
    {bool includePrivate = true}) async {
  final algorithm = Ed25519();
  final keyPair = await algorithm.newKeyPair();
  final publicKey = await keyPair.extractPublicKey();
  final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
  // cryptography supports that via SimpleKeyPairData usually

  // Base64URL encode helpers
  String b64Url(List<int> bytes) => base64UrlEncode(bytes).replaceAll('=', '');

  final jwk = <String, dynamic>{
    "kty": "OKP",
    "crv": "Ed25519",
    "x": b64Url(publicKey.bytes),
  };
  if (includePrivate) {
    jwk["d"] = b64Url(privateKeyBytes);
  }
  return jwk;
}
