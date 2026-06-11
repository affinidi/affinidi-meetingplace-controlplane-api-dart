import 'package:meeting_place_control_plane_api/src/core/did_manager/group_did_manager.dart';
import 'package:meeting_place_control_plane_api/src/core/entity/entity.dart';
import 'package:meeting_place_control_plane_api/src/core/entity/group.dart';
import 'package:meeting_place_control_plane_api/src/core/entity/group_member.dart';
import 'package:meeting_place_control_plane_api/src/core/logger/logger.dart';
import 'package:meeting_place_control_plane_api/src/core/service/device_mapping/device_token_mapping_service.dart';
import 'package:meeting_place_control_plane_api/src/core/service/device_notification/device_notification_service.dart';
import 'package:meeting_place_control_plane_api/src/core/service/device_notification/push_notification_provider.dart';
import 'package:meeting_place_control_plane_api/src/core/service/group/deregister_member_input.dart';
import 'package:meeting_place_control_plane_api/src/core/service/group/group_service.dart';
import 'package:meeting_place_control_plane_api/src/core/service/group/send_message_input.dart';
import 'package:meeting_place_control_plane_api/src/core/service/notification/notification_service.dart';
import 'package:meeting_place_control_plane_api/src/core/storage/exception/already_exists_exception.dart';
import 'package:meeting_place_control_plane_api/src/core/storage/storage.dart';
import 'package:meeting_place_control_plane_api/src/service/did_resolver/local_did_resolver.dart';
import 'package:meeting_place_control_plane_api/src/utils/platform_type.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

class _InMemoryStorage implements Storage {
  final _entities = <String, Map<String, Map<String, dynamic>>>{};
  final _lists = <String, Map<String, Map<String, Map<String, dynamic>>>>{};

  @override
  Future<Storage> connect() async => this;

  @override
  Future<T> create<T extends Entity>(T object) async {
    final entityName = object.getEntityName();
    final id = object.getId();
    _entities.putIfAbsent(entityName, () => {});
    if (_entities[entityName]!.containsKey(id)) {
      throw AlreadyExists();
    }
    _entities[entityName]![id] = object.toJson();
    return object;
  }

  @override
  Future<T> update<T extends Entity>(T object) async {
    _entities.putIfAbsent(object.getEntityName(), () => {});
    _entities[object.getEntityName()]![object.getId()] = object.toJson();
    return object;
  }

  @override
  Future<T?> updateWithCondition<T extends Entity>(
    String entityName,
    String id,
    EntityFromJson<T> fromJson, {
    required T Function(T entity) updateFn,
    required bool Function(T entity) conditionFn,
  }) async => null;

  @override
  Future<T> add<T extends Entity>(String listName, T object) async {
    final listId = object.getListId();
    if (listId == null) {
      throw StateError('List entities must provide getListId()');
    }
    _lists.putIfAbsent(listName, () => {});
    _lists[listName]!.putIfAbsent(listId, () => {});
    if (_lists[listName]![listId]!.containsKey(object.getId())) {
      throw AlreadyExists();
    }
    _lists[listName]![listId]![object.getId()] = object.toJson();
    return object;
  }

  @override
  Future<void> delete(String entityName, String id) async {
    _entities[entityName]?.remove(id);
  }

  @override
  Future<T?> findOneById<T extends Entity>(
    String entityName,
    String id,
    EntityFromJson<T> fromJson,
  ) async {
    final row = _entities[entityName]?[id];
    return row == null ? null : fromJson(row);
  }

  @override
  Future<List<T>> findAllById<T>(
    String entityName,
    String id,
    EntityFromJson<T> fromJson,
  ) async {
    final rows = _lists[entityName]?[id]?.values ?? const [];
    return rows.map(fromJson).toList();
  }

  @override
  Future<int> count(String entityName) async {
    return _entities[entityName]?.length ?? 0;
  }

  @override
  Future<void> deleteFromlist(
    String listName,
    String listId,
    String entityName,
    String id,
  ) async {
    _lists[listName]?[listId]?.remove(id);
  }
}

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

class _FakePushNotificationProvider implements PushNotificationProvider {
  @override
  Future<String?> createPlatformEndpoint({
    required String deviceToken,
    String? metadata,
  }) async => 'arn:example:$deviceToken';

  @override
  Future<void> send({
    required String targetArn,
    required String payload,
  }) async {}
}

class _FakeGroupDidManager implements GroupDidManager {
  @override
  Future<DidDocument> createDid(String offerLink) async {
    throw UnimplementedError();
  }

  @override
  Future<DidManager> get(String groupId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> removeKeys(String groupId) async {}
}

class _TestGroupService extends GroupService {
  _TestGroupService({
    required super.storage,
    required super.notificationService,
    required super.groupDidManager,
    required super.didResolver,
    required super.logger,
  });

  int relayedMessageCount = 0;

  @override
  Future<void> sendMessage(SendMessageInput input) async {
    relayedMessageCount++;
  }
}

void main() {
  group('GroupService.deregisterMember', () {
    late _InMemoryStorage storage;
    late _TestGroupService service;

    setUp(() async {
      storage = _InMemoryStorage();

      final notificationService = NotificationService(
        storage: storage,
        deviceTokenMappingService: DeviceTokenMappingService(storage),
        deviceNotificationService: DeviceNotificationService(
          logger: _NoOpLogger(),
          provider: _FakePushNotificationProvider(),
          mediatorSDK: MeetingPlaceMediatorSDK(
            mediatorDid: 'did:web:mediator.example.com',
            didResolver: LocalDidResolver(),
          ),
        ),
        logger: _NoOpLogger(),
      );

      service = _TestGroupService(
        storage: storage,
        notificationService: notificationService,
        groupDidManager: _FakeGroupDidManager(),
        didResolver: LocalDidResolver(),
        logger: _NoOpLogger(),
      );

      await storage.create(
        Group(
          id: 'group-1',
          offerLink: 'offer-link',
          groupDid: 'did:key:group',
          conrollingDid: 'did:key:owner-controller',
          name: 'Test Group',
          mediatorDid: 'did:web:mediator.example.com',
          createdBy: 'did:key:owner-controller',
          modifiedBy: 'did:key:owner-controller',
          status: GroupStatus.created,
          seqNo: 0,
        ),
      );

      await storage.add(
        GroupMember.entityName,
        GroupMember(
          groupId: 'group-1',
          offerLink: 'offer-link',
          memberDid: 'did:key:member',
          memberPublicKey: 'member-public-key',
          memberReencryptionKey: 'member-rekey',
          memberContactCard: 'member-card',
          platformEndpointArn: 'arn:member',
          platformType: PlatformType.NONE,
          controllingDid: 'did:key:member-controller',
          startSeqNo: 0,
        ),
      );
    });

    test('allows the group owner to remove another member', () async {
      await service.deregisterMember(
        DeregisterMemberInput(
          groupId: 'group-1',
          memberDid: 'did:key:member',
          controllingDid: 'did:key:owner-controller',
          messageToRelay: 'member removed',
        ),
      );

      final remainingMembers = await storage.findAllById<GroupMember>(
        GroupMember.entityName,
        'group-1',
        GroupMember.fromJson,
      );

      expect(service.relayedMessageCount, 1);
      expect(remainingMembers, isEmpty);
    });
  });
}
