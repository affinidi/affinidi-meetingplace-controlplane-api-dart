import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class AuthToken {
  AuthToken({
    required String did,
    required String audience,
    required String issuer,
    required int expiresInMinutes,
  }) {
    _did = did;
    _audience = audience;
    _issuer = issuer;
    _expiresInMinutes = expiresInMinutes;
  }
  late String _did;
  late String _audience;
  late String _issuer;
  late int _expiresInMinutes;

  String signAsJwt(JWTKey signingKey) {
    final jwt = JWT(
      {
        'roles': ['user'],
      },
      subject: _did,
      audience: Audience([_audience]),
      issuer: _issuer,
    );

    return jwt.sign(
      signingKey,
      algorithm: JWTAlgorithm.EdDSA,
      expiresIn: Duration(minutes: _expiresInMinutes),
    );
  }
}
