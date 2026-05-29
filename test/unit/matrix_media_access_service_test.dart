import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:meeting_place_control_plane_api/meeting_place_control_plane_api.dart';
import 'package:meeting_place_control_plane_api/src/core/logger/logger.dart';
import 'package:meeting_place_control_plane_api/src/core/secret_manager/secret_provider.dart';
import 'package:meeting_place_control_plane_api/src/core/service/auth/didcomm_auth.dart';
import 'package:meeting_place_control_plane_api/src/core/service/matrix/matrix_media_access_service.dart';
import 'package:meeting_place_control_plane_api/src/core/web_manager/did_document_manager.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

class _NoopLogger implements Logger {
  @override
  void debug(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void info(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void warn(String message, {Object? error, StackTrace? stackTrace}) {}
}

class _FakeSecretProvider implements SecretProvider {
  @override
  Future<String> getSecret(String secretId) {
    return LocalSecretManager().getSecret(secretId);
  }
}

class _UnusedDidDocumentManager implements DidDocumentManager {
  @override
  Future<DidDocument> getDidDocument() => throw UnimplementedError();
}

class _FakeDidDocumentManager implements DidDocumentManager {
  _FakeDidDocumentManager(this._did);

  final String _did;

  @override
  Future<DidDocument> getDidDocument() async => DidDocument.fromJson({
    '@context': 'https://www.w3.org/ns/did/v1',
    'id': _did,
  });
}

void main() {
  setUpAll(() async {
    await Config().loadConfig(getEnv('ENV'));
    final secretManager = SecretManager.withProvider(_FakeSecretProvider());

    Config().registerSecret(
      'matrixMediaSigningSecret',
      await secretManager.getSecret(getEnv('MATRIX_MEDIA_SIGNING_SECRET')),
    );
  });

  MatrixMediaAccessService buildService() => MatrixMediaAccessService(
    authorizerBuilder: () async => throw UnimplementedError(),
    didDocumentManager: _UnusedDidDocumentManager(),
    logger: _NoopLogger(),
    matrixTokenExpirySeconds: 60,
    matrixMediaAccessTokenExpirySeconds: 60,
  );

  test('createDownloadUrl rejects invalid Matrix media URIs', () async {
    final service = buildService();

    await expectLater(
      () => service.createDownloadUrl(
        did: 'did:key:test',
        homeserver: Uri.parse('https://matrix.example'),
        roomId: '!room:matrix.example',
        mxcUri: 'https://matrix.example/not-mxc',
      ),
      throwsA(
        isA<MatrixMediaAccessException>()
            .having(
              (error) => error.statusCode,
              'statusCode',
              HttpStatus.badRequest,
            )
            .having(
              (error) => error.message,
              'message',
              'media_uri must be a valid mxc URI',
            ),
      ),
    );
  });

  test('downloadMedia rejects invalid access tokens', () async {
    final service = buildService();

    await expectLater(
      () => service.downloadMedia('not-a-valid-token'),
      throwsA(
        isA<MatrixMediaAccessException>()
            .having(
              (error) => error.statusCode,
              'statusCode',
              HttpStatus.forbidden,
            )
            .having(
              (error) => error.message,
              'message',
              'Invalid matrix media access token',
            ),
      ),
    );
  });

  test(
    'issueLoginToken returns a signed JWT with the expected claims',
    () async {
      const controlPlaneDid = 'did:example:controlplane-test';
      const callerDid =
          'did:key:zDnaerx9CtbPJ1q36T5Ln5wYt3MQYeGRG5ehnPAmxcf5zDcec';
      final homeserver = Uri.parse('https://matrix.example.com');

      // Ephemeral P-256 key generated for testing purposes only.
      final testPrivateJwk = <String, dynamic>{
        'kty': 'EC',
        'crv': 'P-256',
        'x': 'Dvnv-V52DS7jcN0NtpD-MdfyT1ypub3Iz1i72AtprGg',
        'y': 'AoZ4166FC637j3wdV_s3XHk6SrBDtpHBf5BVeeKeosk',
        'd': 'Q20Kq7OUrBngOyzlLJJF1XkNk_9Cw4Ly-lmsk8OHRvM',
      };
      final testPublicJwk = Map<String, dynamic>.from(testPrivateJwk)
        ..remove('d');

      final testAuth = DIDCommAuth(
        privateKey: JWTKey.fromJWK(testPrivateJwk),
        publicKey: JWTKey.fromJWK(testPublicJwk),
        jwk: [
          {'privateKeyJwk': testPrivateJwk},
        ],
        logger: _NoopLogger(),
      );

      final service = MatrixMediaAccessService(
        authorizerBuilder: () async => testAuth,
        didDocumentManager: _FakeDidDocumentManager(controlPlaneDid),
        logger: _NoopLogger(),
        matrixTokenExpirySeconds: 60,
        matrixMediaAccessTokenExpirySeconds: 60,
      );

      final token = await service.issueLoginToken(
        did: callerDid,
        homeserver: homeserver,
      );

      expect(token, isNotEmpty);

      final jwt = JWT.decode(token);
      expect(jwt.issuer, equals(controlPlaneDid));
      expect(jwt.audience?.first, equals('https://matrix.example.com'));
      expect(jwt.subject, isNotNull);
      expect(jwt.jwtId, isNotNull);
    },
  );
}
