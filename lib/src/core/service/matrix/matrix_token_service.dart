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
      ), // TODO: make configurable by environment
    ).signAsJwt(signingKey);
  }

  static String _subjectDerivation({
    required String did,
    required String serverName,
  }) {
    return sha256.convert(utf8.encode('$did|$serverName')).toString();
  }

  static String _extractMatrixServerName(String homeserver) {
    final normalized = homeserver.contains('://')
        ? homeserver
        : 'http://$homeserver';

    final host = Uri.parse(normalized).host.trim();
    if (host.isEmpty) {
      throw ArgumentError('Invalid homeserver');
    }
    return host;
  }

  static String _extractAudience(String homeserver) {
    final normalized = homeserver.contains('://')
        ? homeserver
        : 'http://$homeserver';

    final uri = Uri.parse(normalized);
    final host = uri.host.trim();
    if (host.isEmpty) {
      throw ArgumentError('Invalid homeserver');
    }
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
