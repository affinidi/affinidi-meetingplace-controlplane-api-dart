import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:uuid/uuid.dart';

class MatrixToken {
  MatrixToken({
    required String subject,
    required String issuer,
    required String audience,
    required int expiresInMinutes,
  }) : _subject = subject,
       _issuer = issuer,
       _audience = audience,
       _expiresInMinutes = expiresInMinutes;

  final String _subject;
  final String _issuer;
  final String _audience;
  final int _expiresInMinutes;

  String signAsJwt(JWTKey signingKey) {
    final jwt = JWT(
      {},
      subject: _subject,
      issuer: _issuer,
      audience: Audience([_audience]),
      jwtId: const Uuid().v4(),
    );

    return jwt.sign(
      signingKey,
      algorithm: JWTAlgorithm.EdDSA,
      expiresIn: Duration(minutes: _expiresInMinutes),
    );
  }
}
