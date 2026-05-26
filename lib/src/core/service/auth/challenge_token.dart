import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import 'challenge_purpose.dart';

class ChallengeToken {
  ChallengeToken({
    required String did,
    required String audience,
    required String issuer,
    required int expiresInMinutes,
    required String jti,
    required ChallengePurpose purpose,
  }) {
    _did = did;
    _audience = audience;
    _issuer = issuer;
    _expiresInMinutes = expiresInMinutes;
    _jti = jti;
    _purpose = purpose;
  }
  late String _did;
  late String _audience;
  late String _issuer;
  late int _expiresInMinutes;
  late String _jti;
  late ChallengePurpose _purpose;

  String signAsJwt(JWTKey signingKey) {
    final jwt = JWT(
      {
        'roles': ['user'],
        'purpose': _purpose.value,
      },
      subject: _did,
      audience: Audience([_audience]),
      issuer: _issuer,
      jwtId: _jti,
    );

    return jwt.sign(
      signingKey,
      algorithm: JWTAlgorithm.EdDSA,
      expiresIn: Duration(minutes: _expiresInMinutes),
    );
  }
}
