import 'dart:io';

import 'package:meeting_place_control_plane_api/meeting_place_control_plane_api.dart';
import 'package:meeting_place_control_plane_api/src/core/logger/logger.dart';
import 'package:meeting_place_control_plane_api/src/core/secret_manager/secret_provider.dart';
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
}
