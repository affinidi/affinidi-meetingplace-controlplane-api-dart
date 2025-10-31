import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import '../../config/config.dart';
import '../../secret_manager/secret_manager.dart';
import 'auth_token.dart';

class DIDCommAuthChallenge {
  DIDCommAuthChallenge({required JWTKey privateKey}) : _privateKey = privateKey;
  final JWTKey _privateKey;

  String _getAuthChallengeToken(String did) {
    Map config = Config().get('auth');

    final audience = config['challengeTokenAudience'];
    final issuer = config['challengeTokenIssuer'];

    if (audience == null || issuer == null) {
      throw Exception('Audience or issuer for challenge token not defined.');
    }

    return AuthToken(
      did: did,
      audience: audience,
      issuer: issuer,
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

    final ed25519PrivateKeyJWTDoc =
        secret.firstWhere((doc) => doc['privateKeyJwk']['crv'] == 'Ed25519');
    final privateKey = JWTKey.fromJWK(ed25519PrivateKeyJWTDoc['privateKeyJwk']);

    return DIDCommAuthChallenge(privateKey: privateKey)
        ._getAuthChallengeToken(did);
  }
}
