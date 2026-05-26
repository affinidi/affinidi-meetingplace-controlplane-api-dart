import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import '../../../../meeting_place_control_plane_api.dart';
import '../../entity/consumed_challenge.dart';
import '../../logger/logger.dart';
import '../../storage/exception/already_exists_exception.dart';
import '../../storage/storage.dart';
import '../../../utils/date_time.dart';
import 'auth_response.dart';
import 'auth_token.dart';
import 'challenge_purpose.dart';
import 'didcomm_client.dart';
import 'mpx_registration_token.dart';

enum JWTStatus {
  valid,
  expired,
  invalid,
  invalidSubject,
  configurationError,
  missingJti,
  purposeMismatch,
}

class VerifyAuthTokenResult {
  VerifyAuthTokenResult({
    required this.status,
    this.did = '',
    this.verificationMethod = '',
  });
  JWTStatus status;
  String did = '';
  String verificationMethod = '';
}

class VerifyAuthChallengeResult {
  VerifyAuthChallengeResult({required this.status, this.jti});

  final JWTStatus status;
  final String? jti;
}

class DIDCommAuth {
  DIDCommAuth({
    required JWTKey privateKey,
    required JWTKey publicKey,
    required List<dynamic> jwk,
    required Logger logger,
    Storage? storage,
  }) : _privateKey = privateKey,
       _publicKey = publicKey,
       _jwk = jwk,
       _logger = logger,
       _storage = storage;

  final JWTKey _privateKey;
  final JWTKey _publicKey;
  final List<dynamic> _jwk;
  final Logger _logger;
  final Storage? _storage;

  get jwk => _jwk;

  String getAuthToken(
    String did,
    String verificationMethod,
    int expiresInMinutes,
  ) {
    final apiEndpoint = getEnv('API_ENDPOINT');
    return AuthToken(
      did: did,
      audience: apiEndpoint,
      issuer: apiEndpoint,
      verificationMethod: verificationMethod,
      expiresInMinutes: expiresInMinutes,
    ).signAsJwt(_privateKey);
  }

  String getAuthRefreshToken(
    String did,
    String verificationMethod,
    int expiresInMinutes,
  ) {
    final apiEndpoint = getEnv('API_ENDPOINT');
    return AuthToken(
      did: did,
      audience: apiEndpoint,
      issuer: apiEndpoint,
      verificationMethod: verificationMethod,
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

  /// Validates a DIDComm challenge response end-to-end and returns the
  /// authenticated DID. Throws [ChallengeAuthException] on any failure.
  /// [purpose] must match the purpose claim embedded in the challenge token.
  Future<String> authenticateChallengeResponse({
    required String challengeResponse,
    required String didResolverUrl,
    required ChallengePurpose purpose,
  }) async {
    if (_storage == null) {
      throw StateError('Storage is required for challenge auth');
    }

    final AuthenticationResponse authResponse;

    try {
      authResponse = await unpackChallengeResponse(
        challengeResponse,
        didResolverUrl,
      );
    } catch (e, stackTrace) {
      _logger.error(e.toString(), error: e, stackTrace: stackTrace);
      throw ChallengeAuthException(
        AuthenticationResponseType.invalidChallengeResponse.name,
      );
    }

    if (authResponse.type != AuthenticationResponseType.didcommChallengeOk) {
      throw ChallengeAuthException(authResponse.type.name);
    }

    final challengeVerification = verifyAuthChallengeToken(
      authResponse.did,
      authResponse.challenge,
      purpose,
    );

    final jti = challengeVerification.jti;
    if (challengeVerification.status != JWTStatus.valid || jti == null) {
      throw ChallengeAuthException(challengeVerification.status.name);
    }

    try {
      await _storage.create(
        ConsumedChallenge(
          jti: jti,
          ttl: nowUtc().add(const Duration(minutes: 1)),
        ),
      );
    } on AlreadyExists {
      throw ChallengeAuthException('challengeAlreadyUsed');
    }

    return authResponse.did;
  }

  VerifyAuthChallengeResult verifyAuthChallengeToken(
    String did,
    String token,
    ChallengePurpose purpose,
  ) {
    try {
      final jwt = JWT.verify(token, _publicKey);

      if (jwt.payload['sub'] != did) {
        return VerifyAuthChallengeResult(status: JWTStatus.invalidSubject);
      }

      final jti = jwt.jwtId;
      if (jti == null || jti.isEmpty) {
        return VerifyAuthChallengeResult(status: JWTStatus.missingJti);
      }

      final tokenPurpose = ChallengePurpose.fromValue(
        jwt.payload['purpose'] as String? ?? '',
      );
      if (tokenPurpose != purpose) {
        return VerifyAuthChallengeResult(status: JWTStatus.purposeMismatch);
      }

      return VerifyAuthChallengeResult(status: JWTStatus.valid, jti: jti);
    } on JWTExpiredException {
      _logger.info('jwt expires');
      return VerifyAuthChallengeResult(status: JWTStatus.expired);
    } on JWTException catch (ex) {
      _logger.info(ex.message);
      return VerifyAuthChallengeResult(status: JWTStatus.invalid);
    }
  }

  VerifyAuthTokenResult verifyAuthToken(String token) {
    try {
      final jwt = JWT.verify(token, _publicKey);

      return VerifyAuthTokenResult(
        status: JWTStatus.valid,
        did: jwt.payload['sub'],
        verificationMethod: jwt.payload['verificationMethod'] as String? ?? '',
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
