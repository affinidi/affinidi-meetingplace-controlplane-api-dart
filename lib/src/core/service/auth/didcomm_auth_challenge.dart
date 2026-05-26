import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:uuid/uuid.dart';

import '../../config/config.dart';
import '../../config/env_config.dart';
import '../../secret_manager/secret_manager.dart';
import 'challenge_purpose.dart';
import 'challenge_token.dart';

class DIDCommAuthChallenge {
  DIDCommAuthChallenge({required JWTKey privateKey}) : _privateKey = privateKey;
  final JWTKey _privateKey;

  String _getAuthChallengeToken(String did, ChallengePurpose purpose) {
    final apiEndpoint = getEnv('API_ENDPOINT');
    final jti = const Uuid().v4();

    return ChallengeToken(
      did: did,
      audience: apiEndpoint,
      issuer: apiEndpoint,
      verificationMethod: '',
      expiresInMinutes: 1,
      jti: jti,
      purpose: purpose,
    ).signAsJwt(_privateKey);
  }

  /// Returns a JWT signed by the private key of the authoriser, valid for
  /// a short time. The caller should use this token by signing it inside
  /// a didcomm message to prove ownership of the did.
  /// [purpose] must match the endpoint that will consume the challenge.
  static Future<String> generateAuthChallenge({
    required String did,
    required SecretManager secretManager,
    required ChallengePurpose purpose,
  }) async {
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
    )._getAuthChallengeToken(did, purpose);
  }
}
