import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import '../../config/config.dart';
import '../../config/env_config.dart';
import '../../secret_manager/secret_manager.dart';
import 'auth_token.dart';

class DIDCommAuthChallenge {
  DIDCommAuthChallenge({required JWTKey privateKey}) : _privateKey = privateKey;
  final JWTKey _privateKey;

  String _getAuthChallengeToken(String did) {
    final apiEndpoint = getEnv('API_ENDPOINT');

    return AuthToken(
      did: did,
      audience: apiEndpoint,
      issuer: apiEndpoint,
      expiresInMinutes: 1,
    ).signAsJwt(_privateKey);
  }

  /// Returns a JWT signed by the private key of the authoriser, valid for
  /// a short time. The caller should use this token by signing it inside
  /// a didcomm message to prove ownership of the did
  static Future<String> generateAuthChallenge(
    String did,
    SecretManager secretManager,
  ) async {
    final secret = Config().getSecret('didcommauth');

    if (secret == null) {
      throw Exception('Secrets not found.');
    }

    final ed25519PrivateKeyJWTDoc = secret.firstWhere(
      (doc) => doc['privateKeyJwk']['crv'] == 'Ed25519',
    );
    final privateKey = JWTKey.fromJWK(ed25519PrivateKeyJWTDoc['privateKeyJwk']);

    return DIDCommAuthChallenge(
      privateKey: privateKey,
    )._getAuthChallengeToken(did);
  }
}
