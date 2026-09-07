import 'package:meeting_place_control_plane_api/src/core/did_manager/group_did_manager.dart';
import 'package:meeting_place_control_plane_api/src/core/logger/logger.dart';
import 'package:meeting_place_control_plane_api/src/core/service/notification/notification_service.dart';
import 'package:meeting_place_control_plane_api/src/core/storage/storage.dart';
import 'package:ssi/ssi.dart';

/// Shared, behaviour-free fakes for [GroupService] unit tests. Tests that need
/// a fake to return specific data should define a purpose-built one locally.

class NoOpLogger implements Logger {
  @override
  void debug(String message, {Object? error, StackTrace? stackTrace}) {}
  @override
  void info(String message, {Object? error, StackTrace? stackTrace}) {}
  @override
  void warn(String message, {Object? error, StackTrace? stackTrace}) {}
  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {}
}

class FakeGroupDidManager implements GroupDidManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeStorage implements Storage {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeNotificationService implements NotificationService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDidResolver implements DidResolver {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
