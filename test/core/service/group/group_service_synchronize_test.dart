import 'package:meeting_place_control_plane_api/src/core/service/group/group_service.dart';
import 'package:test/test.dart';

import 'group_service_fakes.dart';

/// A single shared [GroupService] whose lock is exercised by concurrent calls.
/// None of the storage / notification / did plumbing is touched by
/// [GroupService.synchronizeGroupCreation], so trivial fakes suffice.
GroupService buildService() => GroupService(
  storage: FakeStorage(),
  notificationService: FakeNotificationService(),
  groupDidManager: FakeGroupDidManager(),
  didResolver: FakeDidResolver(),
  logger: NoOpLogger(),
);

void main() {
  group('GroupService.synchronizeGroupCreation', () {
    test('serializes concurrent critical sections (never overlap)', () async {
      final service = buildService();

      var active = 0;
      var maxActive = 0;

      Future<void> criticalSection() =>
          service.synchronizeGroupCreation(() async {
            active++;
            if (active > maxActive) maxActive = active;
            // Yield so the scheduler could interleave an unprotected section.
            await Future<void>.delayed(Duration.zero);
            active--;
          });

      await Future.wait([for (var i = 0; i < 20; i++) criticalSection()]);

      // With a shared lock, at most one section runs at a time. A per-call
      // Mutex (the fixed bug) would let them interleave, pushing this above 1.
      expect(maxActive, 1);
      expect(active, 0);
    });

    test('preserves a check-then-act limit under concurrent load', () async {
      final service = buildService();

      const limit = 5;
      var count = 0;
      var successes = 0;

      // Mirrors registerOfferGroup: read count, gap, then conditionally create.
      Future<void> registerLikeCall() =>
          service.synchronizeGroupCreation(() async {
            final current = count;
            await Future<void>.delayed(Duration.zero);
            if (current < limit) {
              count++;
              successes++;
            }
          });

      await Future.wait([for (var i = 0; i < 20; i++) registerLikeCall()]);

      // Serialized check-then-act enforces the limit exactly. Without mutual
      // exclusion every task would read count == 0 and all 20 would pass.
      expect(count, limit);
      expect(successes, limit);
    });
  });
}
