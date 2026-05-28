import 'dart:convert';
import 'dart:typed_data';

import 'package:ssi/ssi.dart';

import '../../web_manager/did_web_manager.dart';

class UnsupportedCurveException implements Exception {}

class AuthDidManager {
  AuthDidManager._internal();
  static AuthDidManager? _instance;

  late final Wallet _wallet;
  late final InMemoryKeyStore _keyStore;
  late final DidManager didManager;

  static Future<AuthDidManager> getInstance({
    required List<dynamic> jwks,
  }) async {
    if (_instance == null) {
      final instance = AuthDidManager._internal();
      await instance._init(jwks: jwks);
      _instance = instance;
    }
    return _instance!;
  }

  _init({required List<dynamic> jwks}) async {
    _keyStore = InMemoryKeyStore();
    _wallet = PersistentWallet(_keyStore);

    didManager = DidWebManager(wallet: _wallet, store: InMemoryDidStore());

    for (final jwk in jwks.asMap().entries) {
      if (jwk.value['privateKeyJwk'] == null) continue;

      final keyId = jwk.value['id'];
      final jwkBody = jwk.value['privateKeyJwk'];
      final keyType = _getKeyTypeByCurve(jwkBody['crv']);

      if (keyType == null) {
        continue;
      }

      // PersistentWallet does not support X25519 directly. Skip storing it;
      // ECDH keyAgreement is handled by the P-256 key (used by the app) and
      // the Ed25519 key (auto-derives X25519 via SSI).
      if (keyType == KeyType.x25519) {
        continue;
      }

      Uint8List privateKeyBytes = _decodeBase64Url(jwkBody['d']);

      // ssi's PersistentWallet calls Ed25519KeyPair.fromPrivateKey which
      // expects the 64-byte expanded key (seed[32] + public[32]). JWK 'd'
      // holds only the 32-byte seed, so we splice on the 32-byte public 'x'.
      if (keyType == KeyType.ed25519 && privateKeyBytes.length == 32) {
        final publicBytes = _decodeBase64Url(jwkBody['x']);
        privateKeyBytes = Uint8List.fromList([
          ...privateKeyBytes,
          ...publicBytes,
        ]);
      }

      final key = StoredKey(keyType: keyType, privateKeyBytes: privateKeyBytes);

      await _keyStore.set(keyId, key);

      // Assign relationships based on key type capability
      if (keyType == KeyType.ed25519) {
        // Ed25519 supports auth+assertion; the SSI lib auto-derives X25519
        // for keyAgreement when added with that relationship
        await didManager.addVerificationMethod(
          keyId,
          relationships: {
            VerificationRelationship.authentication,
            VerificationRelationship.assertionMethod,
            VerificationRelationship.keyAgreement,
          },
        );
      } else {
        // P-256, secp256k1: support all relationships including keyAgreement
        await didManager.addVerificationMethod(
          keyId,
          relationships: {
            VerificationRelationship.authentication,
            VerificationRelationship.assertionMethod,
            VerificationRelationship.keyAgreement,
          },
        );
      }
    }
  }

  Uint8List _decodeBase64Url(String input) {
    String normalized = base64Url.normalize(input);
    return base64Url.decode(normalized);
  }

  KeyType? _getKeyTypeByCurve(String crv) {
    switch (crv) {
      case 'P-256':
        return KeyType.p256;
      case 'secp256k1':
        return KeyType.secp256k1;
      case 'Ed25519':
        return KeyType.ed25519;
      case 'X25519':
        return KeyType.x25519;
      default:
        return null;
    }
  }
}
