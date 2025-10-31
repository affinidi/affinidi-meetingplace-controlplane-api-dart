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

    didManager = DidWebManager(
      wallet: _wallet,
      store: InMemoryDidStore(),
    );

    for (final jwk in jwks.asMap().entries) {
      if (jwk.value['privateKeyJwk'] == null) continue;

      final keyId = jwk.value['id'];
      final keyType = _getKeyTypeByCurve(jwk.value['privateKeyJwk']['crv']);

      if (keyType == null) {
        continue;
      }

      final key = StoredKey(
        keyType: keyType,
        privateKeyBytes: _decodeBase64Url(jwk.value['privateKeyJwk']['d']),
      );

      await _keyStore.set(keyId, key);

      // Reflect messaging atlas DID document construction
      if (jwk.key <= 1) {
        await didManager.addVerificationMethod(keyId, relationships: {
          VerificationRelationship.authentication,
          VerificationRelationship.assertionMethod
        });
      } else {
        await didManager.addVerificationMethod(keyId, relationships: {
          VerificationRelationship.keyAgreement,
        });
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
      default:
        return null;
    }
  }
}
