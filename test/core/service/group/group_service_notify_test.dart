import 'dart:convert';

import 'package:meeting_place_control_plane_api/src/core/config/config.dart';
import 'package:meeting_place_control_plane_api/src/core/did_manager/group_did_manager.dart';
import 'package:meeting_place_control_plane_api/src/core/entity/entity.dart';
import 'package:meeting_place_control_plane_api/src/core/entity/group.dart';
import 'package:meeting_place_control_plane_api/src/core/entity/group_member.dart';
import 'package:meeting_place_control_plane_api/src/core/entity/notification_item.dart';
import 'package:meeting_place_control_plane_api/src/core/logger/logger.dart';
import 'package:meeting_place_control_plane_api/src/core/service/group/group_service.dart';
import 'package:meeting_place_control_plane_api/src/core/service/notification/notification_service.dart';
import 'package:meeting_place_control_plane_api/src/core/storage/storage.dart';
import 'package:meeting_place_control_plane_api/src/utils/platform_type.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

class _NoOpLogger implements Logger {
  @override
  void debug(String message, {Object? error, StackTrace? stackTrace}) {}
  @override
  void info(String message, {Object? error, StackTrace? stackTrace}) {}
  @override
  void warn(String message, {Object? error, StackTrace? stackTrace}) {}
  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {}
}

class _FakeGroupDidManager implements GroupDidManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeNotificationItem implements NotificationItem {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeDidResolver implements DidResolver {
  @override
  Future<DidDocument> resolveDid(String did) async {
    return DidDocument.fromJson(
      jsonEncode({
        '@context': ['https://www.w3.org/ns/did/v1'],
        'id': did,
      }),
    );
  }
}

/// Records every recipient DID passed to [notifyChannelGroup].
class _CapturingNotificationService implements NotificationService {
  final List<String> notifiedRecipientDids = [];

  @override
  Future<NotificationItem> notifyChannelGroup({
    required String type,
    required PlatformType platformType,
    required String platformEndpointArn,
    required String authDid,
    required String recipientDid,
  }) async {
    notifiedRecipientDids.add(recipientDid);
    return _FakeNotificationItem();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Returns a fixed group and member list regardless of id.
class _FakeStorage implements Storage {
  _FakeStorage({required this.group, required this.members});

  final Group group;
  final List<GroupMember> members;

  @override
  Future<T?> findOneById<T extends Entity>(
    String entityName,
    String id,
    EntityFromJson<T> fromJson,
  ) async {
    if (entityName == Group.entityName) return group as T;
    return null;
  }

  @override
  Future<List<T>> findAllById<T>(
    String entityName,
    String id,
    EntityFromJson<T> fromJson,
  ) async {
    if (entityName == GroupMember.entityName) return members.cast<T>();
    return <T>[];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

GroupMember _member({
  required String memberDid,
  required String controllingDid,
}) => GroupMember(
  groupId: 'group-1',
  offerLink: 'offer-1',
  memberDid: memberDid,
  memberContactCard: '',
  platformEndpointArn: 'arn:$memberDid',
  platformType: PlatformType.PUSH_NOTIFICATION,
  controllingDid: controllingDid,
  startSeqNo: 0,
);

Group _group() => Group(
  id: 'group-1',
  offerLink: 'offer-1',
  groupDid: 'did:group',
  conrollingDid: 'did:alice-ctrl',
  name: 'Test Group',
  mediatorDid: 'did:mediator',
  createdBy: 'did:alice-ctrl',
  modifiedBy: 'did:alice-ctrl',
  status: GroupStatus.created,
  seqNo: 0,
);

void main() {
  setUpAll(() {
    Config().registerSecret('hashSecret', {'secret': 'test-secret'});
  });

  late _CapturingNotificationService notificationService;

  final alice = _member(
    memberDid: 'did:alice',
    controllingDid: 'did:alice-ctrl',
  );
  final bob = _member(memberDid: 'did:bob', controllingDid: 'did:bob-ctrl');
  final carol = _member(
    memberDid: 'did:carol',
    controllingDid: 'did:carol-ctrl',
  );

  GroupService buildService() {
    notificationService = _CapturingNotificationService();
    return GroupService(
      storage: _FakeStorage(group: _group(), members: [alice, bob, carol]),
      notificationService: notificationService,
      groupDidManager: _FakeGroupDidManager(),
      didResolver: _FakeDidResolver(),
      logger: _NoOpLogger(),
    );
  }

  group('GroupService.notifyChannel', () {
    test('memberDid null: notifies all members except the sender', () async {
      final service = buildService();

      await service.notifyChannel(
        offerLink: 'offer-1',
        groupDid: 'did:group',
        controllingDid: 'did:alice-ctrl',
        type: 'chat-activity',
      );

      expect(
        notificationService.notifiedRecipientDids,
        unorderedEquals(['did:bob', 'did:carol']),
      );
    });

    test('memberDid set: notifies only that member', () async {
      final service = buildService();

      await service.notifyChannel(
        offerLink: 'offer-1',
        groupDid: 'did:group',
        controllingDid: 'did:alice-ctrl',
        type: 'chat-activity',
        memberDid: 'did:bob',
      );

      expect(notificationService.notifiedRecipientDids, equals(['did:bob']));
    });

    test('memberDid not in group: throws GroupMemberNotInGroup', () async {
      final service = buildService();

      expect(
        () => service.notifyChannel(
          offerLink: 'offer-1',
          groupDid: 'did:group',
          controllingDid: 'did:alice-ctrl',
          type: 'chat-activity',
          memberDid: 'did:not-a-member',
        ),
        throwsA(isA<GroupMemberNotInGroup>()),
      );
    });
  });
}
