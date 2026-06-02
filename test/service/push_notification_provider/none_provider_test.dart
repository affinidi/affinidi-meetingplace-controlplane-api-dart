import 'package:meeting_place_control_plane_api/src/core/logger/logger.dart';
import 'package:meeting_place_control_plane_api/src/service/push_notification_provider/none_provider.dart';
import 'package:test/test.dart';

class _NoopLogger implements Logger {
  @override
  void debug(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void info(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void warn(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {}
}

void main() {
  late NoneProvider provider;

  setUp(() {
    provider = NoneProvider(logger: _NoopLogger());
  });

  group('NoneProvider.createPlatformEndpoint', () {
    test('returns same endpoint for same deviceToken and metadata', () async {
      final a = await provider.createPlatformEndpoint(
        deviceToken: 'token-1',
        metadata: 'meta',
      );
      final b = await provider.createPlatformEndpoint(
        deviceToken: 'token-1',
        metadata: 'meta',
      );
      expect(a, equals(b));
    });

    test(
      'returns same endpoint for same deviceToken without metadata',
      () async {
        final a = await provider.createPlatformEndpoint(deviceToken: 'token-1');
        final b = await provider.createPlatformEndpoint(deviceToken: 'token-1');
        expect(a, equals(b));
      },
    );

    test('returns different endpoints for different deviceTokens', () async {
      final a = await provider.createPlatformEndpoint(deviceToken: 'token-1');
      final b = await provider.createPlatformEndpoint(deviceToken: 'token-2');
      expect(a, isNot(equals(b)));
    });

    test('returns different endpoints when metadata differs', () async {
      final a = await provider.createPlatformEndpoint(
        deviceToken: 'token-1',
        metadata: 'meta-a',
      );
      final b = await provider.createPlatformEndpoint(
        deviceToken: 'token-1',
        metadata: 'meta-b',
      );
      expect(a, isNot(equals(b)));
    });

    test('endpoint is prefixed with "none:"', () async {
      final endpoint = await provider.createPlatformEndpoint(
        deviceToken: 'token-1',
      );
      expect(endpoint, startsWith('none:'));
    });
  });
}
