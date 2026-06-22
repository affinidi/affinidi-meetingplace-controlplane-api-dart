import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import '../../../../meeting_place_control_plane_api.dart';
import 'matrix_token.dart';

class MatrixTokenService {
  static Future<String> issueToken({
    required String did,
    required String homeserver,
  }) async {
    final serverName = _extractMatrixServerName(homeserver);
    final audience = _extractAudience(homeserver);
    final subject = _subjectDerivation(did: did, serverName: serverName);
    final signingKey = _getSigningKey();

    return MatrixToken(
      subject: subject,
      issuer: getEnv('CONTROL_PLANE_DID'),
      audience: audience,
      expiresInMinutes: int.parse(
        getEnvOrNull('MATRIX_TOKEN_EXPIRY_IN_MINUTES') ?? '5',
      ),
    ).signAsJwt(signingKey);
  }

  static String _subjectDerivation({
    required String did,
    required String serverName,
  }) {
    return sha256.convert(utf8.encode('$did|$serverName')).toString();
  }

  static Uri _parseHomeserverUri(String homeserver) {
    final normalized = homeserver.contains('://')
        ? homeserver
        : 'http://$homeserver';
    final uri = Uri.parse(normalized);
    if (uri.host.trim().isEmpty) {
      throw ArgumentError('Invalid homeserver');
    }
    return uri;
  }

  static String _extractMatrixServerName(String homeserver) {
    return _parseHomeserverUri(homeserver).host.trim();
  }

  static String _extractAudience(String homeserver) {
    final uri = _parseHomeserverUri(homeserver);
    final host = uri.host.trim();
    final authority = uri.hasPort ? '$host:${uri.port}' : host;
    final scheme = uri.scheme.trim().isEmpty ? 'http' : uri.scheme.trim();
    return '$scheme://$authority';
  }

  static JWTKey _getSigningKey() {
    final keys = Config().getSecret('didcommauth');
    final signingKey = JWTKey.fromJWK(
      keys.firstWhere(
        (doc) => doc['privateKeyJwk']['crv'] == 'Ed25519',
      )['privateKeyJwk'],
    );
    return signingKey;
  }
}
