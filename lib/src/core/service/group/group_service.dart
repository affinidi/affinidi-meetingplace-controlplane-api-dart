import 'package:mutex/mutex.dart';

import 'package:ssi/ssi.dart';

import '../../entity/group.dart';
import '../../entity/group_member.dart';
import '../../logger/logger.dart';
import '../notification/notification_service.dart';
import 'add_group_member_input.dart';
import 'create_group_input.dart';
import '../../storage/storage.dart';
import 'delete_group_input.dart';
import 'deregister_member_input.dart';
import 'group_utils.dart';

class GroupCreationFailed implements Exception {}

class GroupNotFound implements Exception {
  GroupNotFound({required this.groupId});

  final String groupId;
}

class GroupDeleted implements Exception {
  GroupDeleted({required this.groupId});

  final String groupId;
}

class GroupMemberNotInGroup implements Exception {
  GroupMemberNotInGroup({required this.groupId});

  final String groupId;
}

class GroupPermissionDenied implements Exception {}

class GroupAddMemberFailed implements Exception {}

class GroupService {
  GroupService({
    required Storage storage,
    required NotificationService notificationService,
    required DidResolver didResolver,
    required Logger logger,
  }) : _storage = storage,
       _notificationService = notificationService,
       _didResolver = didResolver,
       _logger = logger;

  final Storage _storage;
  final NotificationService _notificationService;
  final DidResolver _didResolver;
  final Logger _logger;

  final _groupCreationMutex = Mutex();

  /// Serializes group-creation critical sections (e.g. the group-count limit
  /// check-then-create) across concurrent requests within this process.
  Future<T> synchronizeGroupCreation<T>(Future<T> Function() action) =>
      _groupCreationMutex.protect(action);

  Future<Group> createGroup(CreateGroupInput input) async {
    final group = Group(
      id: GroupUtils.generateGroupId(offerLink: input.offerLink),
      offerLink: input.offerLink,
      conrollingDid: input.controllingDid,
      name: input.groupName,
      mediatorDid: input.mediatorDid,
      createdBy: input.createdBy,
      modifiedBy: input.modifiedBy,
      status: GroupStatus.created,
      seqNo: 0,
    );

    try {
      return _storage.create(group);
    } catch (e, stackTrace) {
      _logger.error(
        'Error creating group $e',
        error: e,
        stackTrace: stackTrace,
      );
      throw GroupCreationFailed();
    }
  }

  Future<Group> getGroup(String id) async {
    final group = await _storage.findOneById(
      Group.entityName,
      id,
      Group.fromJson,
    );

    if (group == null) throw GroupNotFound(groupId: id);
    if (group.status == GroupStatus.deleted) throw GroupDeleted(groupId: id);
    return group;
  }

  Future<int> countGroups() async {
    return _storage.count(Group.entityName);
  }

  Future<GroupMember> addMemberToGroup(AddGroupMemberInput input) async {
    try {
      final group = await getGroup(input.groupId);

      await _checkPermissionToRunGroupAction(
        groupId: group.id,
        controllerDid: input.authDid,
      );

      final groupMember = await _storage.add(
        GroupMember.entityName,
        GroupMember(
          groupId: input.groupId,
          offerLink: input.offerLink,
          memberDid: input.memberDid,
          memberContactCard: input.memberContactCard,
          platformEndpointArn: input.platformEndpointArn,
          platformType: input.platformType,
          controllingDid: input.controllingDid,
          startSeqNo: group.seqNo,
        ),
      );

      return groupMember;
    } on GroupPermissionDenied {
      rethrow;
    } catch (e, stackTrace) {
      _logger.error(
        'Error adding member to group $e',
        error: e,
        stackTrace: stackTrace,
      );
      throw GroupAddMemberFailed();
    }
  }

  Future<GroupMember> getGroupMemberByControllingDid(
    String controllingDid, {
    required String groupId,
  }) async {
    // TODO: add pagination
    final groupMembers = await _storage.findAllById(
      GroupMember.entityName,
      groupId,
      GroupMember.fromJson,
    );

    return groupMembers.firstWhere(
      (groupMember) => groupMember.controllingDid == controllingDid,
      orElse: () => throw GroupMemberNotInGroup(groupId: groupId),
    );
  }

  Future<void> deregisterMember(DeregisterMemberInput input) async {
    final group = await getGroup(input.groupId);

    final groupMembers = await _getGroupMembers(group.id);
    final groupMember = groupMembers.firstWhere(
      (m) => m.memberDid == input.memberDid,
      orElse: () => throw GroupMemberNotInGroup(groupId: group.id),
    );

    final isOwner = group.conrollingDid == input.controllingDid;
    final isSelfDeregister = groupMember.controllingDid == input.controllingDid;

    if (!isOwner && !isSelfDeregister) {
      throw GroupPermissionDenied();
    }

    await _storage.deleteFromlist(
      GroupMember.entityName,
      group.id,
      GroupMember.entityName,
      groupMember.memberDid,
    );
  }

  Future<void> notifyChannel({
    required String groupId,
    required String controllingDid,
    required String type,
    String? memberDid,
  }) async {
    await getGroup(groupId);

    final sender = await getGroupMemberByControllingDid(
      controllingDid,
      groupId: groupId,
    );

    final groupMembers = await _getGroupMembers(groupId);

    final recipients = memberDid == null
        ? groupMembers.where((m) => m.memberDid != sender.memberDid)
        : [
            groupMembers.firstWhere(
              (m) => m.memberDid == memberDid,
              orElse: () => throw GroupMemberNotInGroup(groupId: groupId),
            ),
          ];

    await Future.wait(
      recipients.map((groupMember) async {
        try {
          final recipientDidDoc = await _didResolver.resolveDid(
            groupMember.memberDid,
          );

          await _notificationService.notifyChannelGroup(
            type: type,
            platformType: groupMember.platformType,
            platformEndpointArn: groupMember.platformEndpointArn,
            authDid: controllingDid,
            recipientDid: recipientDidDoc.id,
          );
        } catch (e, stackTrace) {
          _logger.error(
            'Notification could not be sent to group member: ${e.toString()}',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }).toList(),
    );
  }

  Future<List<GroupMember>> _getGroupMembers(final String groupId) {
    return _storage.findAllById<GroupMember>(
      GroupMember.entityName,
      groupId,
      GroupMember.fromJson,
    );
  }

  Future<void> deleteGroup(DeleteGroupInput input) async {
    final group = await getGroup(input.groupId);

    if (group.createdBy != input.controllingDid) {
      throw GroupPermissionDenied();
    }

    group.status = GroupStatus.deleted;
    await _storage.update(group);
    await _storage.delete(GroupMember.entityName, input.groupId);
  }

  _checkPermissionToRunGroupAction({
    required String groupId,
    required String controllerDid,
  }) async {
    final group = await getGroup(groupId);
    if (group.conrollingDid != controllerDid) {
      throw GroupPermissionDenied();
    }
  }
}
