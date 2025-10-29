import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import '../../config/config.dart';
import '../../logger/logger.dart';
import 'auth_response.dart';
import 'auth_token.dart';
import 'didcomm_client.dart';
import 'mpx_registration_token.dart';

enum JWTStatus { valid, expired, invalid, invalidSubject, configurationError }

class VerifyAuthTokenResult {
  VerifyAuthTokenResult({required this.status, this.did = ''});
  JWTStatus status;
  String did = '';
}

class DIDCommAuth {
  DIDCommAuth({
    required JWTKey privateKey,
    required JWTKey publicKey,
    required List<dynamic> jwk,
    required Logger logger,
  })  : _privateKey = privateKey,
        _publicKey = publicKey,
        _jwk = jwk,
        _logger = logger {
    Map config = Config().get('auth');

    if (config['tokenAudience'] == null ||
        config['tokenIssuer'] == null ||
        config['refreshTokenIssuer'] == null) {
      throw Exception('One of auth token configurations variables missing.');
    }

    _authTokenAudience = config['tokenAudience'];
    _authTokenIssuer = config['tokenIssuer'];
    _authRefreshTokenIssuer = config['refreshTokenIssuer'];
  }
  final JWTKey _privateKey;
  final JWTKey _publicKey;
  final List<dynamic> _jwk;
  final Logger _logger;

  late final String _authTokenAudience;
  late final String _authTokenIssuer;
  late final String _authRefreshTokenIssuer;

  get jwk => _jwk;

  String getAuthToken(String did, int expiresInMinutes) {
    return AuthToken(
      did: did,
      audience: _authTokenAudience,
      issuer: _authTokenIssuer,
      expiresInMinutes: expiresInMinutes,
    ).signAsJwt(_privateKey);
  }

  String getAuthRefreshToken(String did, int expiresInMinutes) {
    return AuthToken(
      did: did,
      audience: _authTokenAudience,
      issuer: _authRefreshTokenIssuer,
      expiresInMinutes: expiresInMinutes,
    ).signAsJwt(_privateKey);
  }

  String getApiDiscoveryToken({
    required String issuer,
    required Map data,
    required int expiresInMinutes,
  }) {
    return MpxRegistrationToken(
      issuer: issuer,
      data: data,
      expiresInMinutes: expiresInMinutes,
    ).signAsJwt(_privateKey);
  }

  Future<AuthenticationResponse> unpackChallengeResponse(
    String challengeResponse,
    String didResolverUrl,
  ) async {
    final authClient = AuthClient(privateJwks: _jwk);
    return authClient.unpackChallengeResponse(
      challengeResponse,
      didResolverUrl,
    );
  }

  JWTStatus verifyAuthChallengeToken(String did, String token) {
    try {
      final jwt = JWT.verify(token, _publicKey);

      if (jwt.payload['sub'] != did) {
        return JWTStatus.invalidSubject;
      }
      return JWTStatus.valid;
    } on JWTExpiredException {
      _logger.info('jwt expires');
      return JWTStatus.expired;
    } on JWTException catch (ex) {
      _logger.info(ex.message);
      return JWTStatus.invalid;
    }
  }

  VerifyAuthTokenResult verifyAuthToken(String token) {
    try {
      final jwt = JWT.verify(token, _publicKey);

      return VerifyAuthTokenResult(
        status: JWTStatus.valid,
        did: jwt.payload['sub'],
      );
    } on JWTExpiredException {
      _logger.info('jwt expires');
      return VerifyAuthTokenResult(status: JWTStatus.expired);
    } on JWTException catch (ex) {
      _logger.info(ex.message);
      return VerifyAuthTokenResult(status: JWTStatus.invalid);
    }
  }
}
