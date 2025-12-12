import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class MpxRegistrationToken {
  MpxRegistrationToken({
    required String issuer,
    required Map data,
    required int expiresInMinutes,
  }) : _issuer = issuer,
       _data = data,
       _expiresInMinutes = expiresInMinutes;
  final String _issuer;
  final Map _data;
  final int _expiresInMinutes;

  String signAsJwt(JWTKey signingKey) {
    final jwt = JWT({'data': _data}, issuer: _issuer);
    return jwt.sign(
      signingKey,
      algorithm: JWTAlgorithm.EdDSA,
      expiresIn: Duration(minutes: _expiresInMinutes),
    );
  }
}
