import 'package:meeting_place_core/meeting_place_core.dart' show GroupMessage;
import 'package:mutex/mutex.dart';
import 'dart:convert';

import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import 'package:ssi/ssi.dart';

import '../../did_manager/group_did_manager.dart';
import '../../entity/group.dart';
import '../../entity/group_member.dart';
import '../../logger/logger.dart';
import '../notification/notification_service.dart';
import '../recrypt/recrypt_service.dart';
import 'add_group_member_input.dart';
import 'create_group_input.dart';
import '../../storage/storage.dart';
import 'delete_group_input.dart';
import 'deregister_member_input.dart';
import 'group_utils.dart';
import 'send_message_input.dart';

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
    required GroupDidManager groupDidManager,
    required DidResolver didResolver,
    required Logger logger,
  }) : _storage = storage,
       _notificationService = notificationService,
       _groupDidManager = groupDidManager,
       _didResolver = didResolver,
       _logger = logger;

  final Storage _storage;
  final NotificationService _notificationService;
  final GroupDidManager _groupDidManager;
  final RecryptService _recryptService = RecryptService.getInstance();
  final DidResolver _didResolver;
  final Logger _logger;

  final mutex = Mutex();

  Future<Group> createGroup(CreateGroupInput input) async {
    final groupDidDoc = await _groupDidManager.createDid(input.offerLink);

    final group = Group(
      id: GroupUtils.generateGroupId(
        offerLink: input.offerLink,
        groupDid: groupDidDoc.id,
      ),
      offerLink: input.offerLink,
      conrollingDid: input.controllingDid,
      groupDid: groupDidDoc.id,
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
          memberPublicKey: input.memberPublicKey,
          memberReencryptionKey: input.memberReencryptionKey,
          memberVCard: input.memberVCard,
          platformEndpointArn: input.platformEndpointArn,
          platformType: input.platformType,
          controllingDid: input.controllingDid,
          startSeqNo: group.seqNo,
        ),
      );

      await _allowMemberToMessageGroup(
        groupId: input.groupId,
        memberDid: input.memberDid,
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

    final groupMember = await getGroupMemberByControllingDid(
      input.controllingDid,
      groupId: group.id,
    );

    await sendMessage(
      SendMessageInput(
        offerLink: group.offerLink,
        groupDid: group.groupDid,
        controllingDid: input.controllingDid,
        messagePayload: input.messageToRelay,
        incSeqNo: false,
        notify: false,
      ),
    );

    await _storage.deleteFromlist(
      GroupMember.entityName,
      group.id,
      GroupMember.entityName,
      groupMember.memberDid,
    );
  }

  Future<void> sendMessage(SendMessageInput input) async {
    final groupId = GroupUtils.generateGroupId(
      offerLink: input.offerLink,
      groupDid: input.groupDid,
    );

    final groupDidManager = await _groupDidManager.get(groupId);

    // ensure group exists / not deleted
    await getGroup(groupId);

    final group = await _storage.updateWithCondition(
      Group.entityName,
      groupId,
      Group.fromJson,
      updateFn: (group) {
        if (input.incSeqNo) group.incrementSeqNo();
        return group;
      },
      conditionFn: (group) => group.status != GroupStatus.deleted,
    );

    if (group == null) {
      throw GroupNotFound(groupId: groupId);
    }

    // Authenticate to mediator before iterating members to use cached access
    // when running in paralell
    final mediatorSDK = MeetingPlaceMediatorSDK(
      mediatorDid: group.mediatorDid,
      didResolver: _didResolver,
    );

    final sender = await getGroupMemberByControllingDid(
      input.controllingDid,
      groupId: groupId,
    );

    final groupMembers = await _getGroupMembers(groupId);

    await Future.wait(
      groupMembers.map((groupMember) async {
        // Skip sender
        if (groupMember.memberDid == sender.memberDid) {
          return Future.value();
        }

        final recipientDidDoc = await _didResolver.resolveDid(
          groupMember.memberDid,
        );

        final payload = jsonDecode(
          utf8.decode(base64.decode(input.messagePayload)),
        );

        final messageToSend = GroupMessage.create(
          from: group.groupDid,
          to: [recipientDidDoc.id],
          iv: payload['iv'],
          authenticationTag: payload['authenticationTag'],
          ciphertext: payload['ciphertext'],
          preCapsule: _recryptService
              .reEncryptCapsule(
                payload['capsule'],
                reencryptionKeyBase64: groupMember.memberReencryptionKey,
              )
              .toBase64(),
          fromDid: sender.memberDid,
          seqNo: group.seqNo,
        );

        try {
          await mediatorSDK.sendMessage(
            messageToSend,
            senderDidManager: groupDidManager,
            recipientDidDocument: recipientDidDoc,
            mediatorDid: group.mediatorDid,
          );

          if (input.notify) {
            await _notificationService.notifyChannelGroup(
              type: 'chat-activity',
              platformType: groupMember.platformType,
              platformEndpointArn: groupMember.platformEndpointArn,
              authDid: input.controllingDid,
              recipientDid: recipientDidDoc.id,
            );
          }
        } on MeetingPlaceMediatorSDKException catch (e, stackTrace) {
          final clientException = e.innerException;
          if (clientException is MediatorClientException) {
            _logger.error(
              clientException.innerMessage,
              error: clientException,
              stackTrace: stackTrace,
            );
          }
          _logger.error(
            'Message could not be send from group to member: ${e.message}',
            error: e,
            stackTrace: stackTrace,
          );
        } catch (e, stackTrace) {
          _logger.error(
            'Message could not be send from group to member: ${e.toString()}',
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

    await sendMessage(
      SendMessageInput(
        offerLink: group.offerLink,
        groupDid: group.groupDid,
        controllingDid: input.controllingDid,
        messagePayload: input.messageToRelay,
        incSeqNo: false,
        notify: false,
      ),
    );

    group.status = GroupStatus.deleted;
    await _storage.update(group);
    await _storage.delete(GroupMember.entityName, input.groupId);
    await _groupDidManager.removeKeys(input.groupId);
  }

  Future<void> _allowMemberToMessageGroup({
    required String groupId,
    required String memberDid,
  }) async {
    final group = await getGroup(groupId);

    final groupDidManager = await _groupDidManager.get(groupId);
    final didManagerDidDoc = await groupDidManager.getDidDocument();

    final mediatorSDK = MeetingPlaceMediatorSDK(
      mediatorDid: group.mediatorDid,
      didResolver: _didResolver,
    );

    await mediatorSDK.updateAcl(
      ownerDidManager: groupDidManager,
      acl: AccessListAdd(
        ownerDid: didManagerDidDoc.id,
        granteeDids: [memberDid],
      ),
      mediatorDid: group.mediatorDid,
    );
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
