import 'dart:async';
import '../../config/config.dart';
import '../../entity/pending_notification.dart';
import '../../logger/logger.dart';
import '../device_notification/device_notification.dart';
import '../device_notification/device_notification_exception.dart';
import '../device_notification/notification/group_membership_finalised.dart';
import '../device_notification/notification/notify_invitation_outreach.dart';
import '../device_notification/notification/offer_acceptance.dart';
import '../device_notification/notification/offer_acceptance_group.dart';
import '../device_notification/notification/offer_finalised.dart';
import 'create_notification_channel_input.dart';
import 'notify_acceptance_input.dart';
import 'notify_channel_input.dart';
import 'notify_finalise_acceptance_input.dart';
import '../../storage/storage.dart';
import '../../../utils/hash.dart';
import '../../../utils/platform_type.dart';
import '../device_mapping/device_token_mapping_service.dart';
import '../device_notification/device_notification_service.dart';
import '../device_notification/notification/notify_channel.dart';
import '../../entity/notification_channel.dart';
import '../../entity/notification_item.dart';
import 'package:uuid/uuid.dart';

import 'notify_group_membership_finalised_input.dart';
import 'notify_outreach_input.dart';

const oneMessage = 1;

class NotificationItemPayloadMissing implements Exception {}

class NotificationChannelNotFound implements Exception {}

class NotAuthorizedException implements Exception {}

class NotificationService {
  NotificationService({
    required Storage storage,
    required DeviceTokenMappingService deviceTokenMappingService,
    required DeviceNotificationService deviceNotificationService,
    required Logger logger,
  }) : _storage = storage,
       _deviceTokenMappingService = deviceTokenMappingService,
       _deviceNotificationService = deviceNotificationService,
       _logger = logger;

  final Storage _storage;
  final DeviceTokenMappingService _deviceTokenMappingService;
  final DeviceNotificationService _deviceNotificationService;
  final Logger _logger;

  Future<NotificationChannel> createNotificationChannel(
    CreateNotificationChannelInput input,
    String authDid,
  ) async {
    final notificationChannelId = _generateNotificationChannelId(
      ownerDid: input.didUsedForAcceptance,
      theirDid: input.theirDid,
    );

    final existingNotificationChannel = await _queryNotificationChannel(
      notificationChannelId,
    );

    if (existingNotificationChannel != null) {
      _logger.info('notification channel exists already');
      return existingNotificationChannel;
    }

    final deviceTokenMapping = await _deviceTokenMappingService
        .getDeviceTokenMapping(
          devicePlatform: input.platformType,
          deviceToken: input.deviceToken,
        );

    return _storage.create(
      NotificationChannel(
        notificationChannelId: notificationChannelId,
        did: input.didUsedForAcceptance,
        peerDid: input.theirDid,
        platformEndpointArn: deviceTokenMapping.platformEndpointArn,
        platformType: deviceTokenMapping.platformType,
        createdBy: authDid,
      ),
    );
  }

  Future<NotificationItem> saveNotificationItem(
    NotificationItem notificationItem,
  ) async {
    _logger.info('save notification item');
    await _storage.create(notificationItem);

    final pendingNotification = PendingNotification(
      id: notificationItem.id,
      deviceHash: notificationItem.deviceHash,
    );

    await _storage.add(
      pendingNotification.getEntityName(),
      pendingNotification,
    );

    return notificationItem;
  }

  Future<List<NotificationItem>> getPendingNotifications(
    String deviceHash,
  ) async {
    final pendingNotifications = await _storage.findAllById(
      PendingNotification.entityName,
      deviceHash,
      PendingNotification.fromJson,
    );

    final List<NotificationItem> notifications = [];
    for (var pendingNotification in pendingNotifications) {
      final notification = await _storage.findOneById(
        NotificationItem.entityName,
        pendingNotification.getId(),
        NotificationItem.fromJson,
      );

      if (notification != null) {
        notifications.add(notification);
      }
    }

    return notifications;
  }

  Future<NotificationItem> notifyChannel(
    NotifyChannelInput input,
    String authDid,
  ) async {
    final notificationChannel = await _queryNotificationChannel(
      input.notificationChannelId,
    );

    if (notificationChannel == null) {
      throw NotificationChannelNotFound();
    }

    final notificationId = _generateNotificationItemId();
    final deviceHash = _deviceTokenMappingService.generateDeviceHash(
      notificationChannel.platformEndpointArn,
    );

    final pendingNotifications = await getPendingNotifications(deviceHash);
    final pendingNotificationCount =
        pendingNotifications.length + (input.type == 'chat-activity' ? 1 : 0);

    final notifyChannelNotification = NotifyChannelNotification(
      badgeCount: pendingNotificationCount,
      data: DeviceNotificationData(
        id: notificationId,
        pendingCount: pendingNotificationCount,
      ),
    );

    final notificationData = _deviceNotificationService
        .getDeviceNotificationData(
          notificationChannel.platformType,
          notifyChannelNotification,
        );

    final notificationItem = await saveNotificationItem(
      NotificationItem.channelActivity(
        id: notificationId,
        deviceHash: deviceHash,
        consumerAuthDid: authDid,
        acceptChannelDid: input.did,
        type: input.type,
        payload: notificationData,
      ),
    );

    await _deviceNotificationService.notify(
      platformType: notificationChannel.platformType,
      platformEndpointArn: notificationChannel.platformEndpointArn,
      notification: notifyChannelNotification,
    );

    return notificationItem;
  }

  Future<NotificationItem> notifyChannelGroup({
    required String type,
    required PlatformType platformType,
    required String platformEndpointArn,
    required String authDid,
    required String recipientDid,
  }) async {
    final notificationId = _generateNotificationItemId();

    final deviceHash = _deviceTokenMappingService.generateDeviceHash(
      platformEndpointArn,
    );

    final pendingNotifications = await getPendingNotifications(deviceHash);
    final pendingNotificationCount =
        pendingNotifications.length + (type == 'chat-activity' ? 1 : 0);

    final notifyChannelNotification = NotifyChannelNotification(
      badgeCount: pendingNotificationCount,
      data: DeviceNotificationData(
        id: notificationId,
        pendingCount: pendingNotificationCount,
      ),
    );

    final notificationItem = saveNotificationItem(
      NotificationItem.channelActivity(
        id: notificationId,
        deviceHash: deviceHash,
        consumerAuthDid: authDid,
        acceptChannelDid: recipientDid,
        type: type,
        payload: _deviceNotificationService.getDeviceNotificationData(
          platformType,
          notifyChannelNotification,
        ),
      ),
    );

    await _deviceNotificationService.notify(
      platformType: platformType,
      platformEndpointArn: platformEndpointArn,
      notification: notifyChannelNotification,
    );

    return notificationItem;
  }

  Future<NotificationItem> notifyAcceptance(NotifyAcceptanceInput input) async {
    final deviceHash = _deviceTokenMappingService.generateDeviceHash(
      input.offer.platformEndpointArn,
    );

    final notificationId = _generateNotificationItemId();
    final pendingNotifications = await getPendingNotifications(deviceHash);
    final pendingNotificationCount = pendingNotifications.length + 1;

    final notification = OfferAcceptanceNotification(
      badgeCount: pendingNotificationCount,
      offerName: input.offer.name,
      sender: input.senderInfo,
      data: DeviceNotificationData(
        id: notificationId,
        pendingCount: pendingNotificationCount,
      ),
    );

    final notificationItem = await saveNotificationItem(
      NotificationItem.invitationAccept(
        id: notificationId,
        deviceHash: deviceHash,
        consumerAuthDid: input.authDid,
        acceptChannelDid: input.didUsedForAcceptance,
        offerLink: input.offer.offerLink,
        payload: _deviceNotificationService.getDeviceNotificationData(
          input.offer.platformType,
          notification,
        ),
      ),
    );

    await _deviceNotificationService.notify(
      platformType: input.offer.platformType,
      platformEndpointArn: input.offer.platformEndpointArn,
      notification: notification,
    );

    return notificationItem;
  }

  Future<NotificationItem> notifyAcceptanceGroup(
    NotifyAcceptanceInput input,
  ) async {
    final deviceHash = _deviceTokenMappingService.generateDeviceHash(
      input.offer.platformEndpointArn,
    );

    final notificationId = _generateNotificationItemId();
    final pendingNotifications = await getPendingNotifications(deviceHash);
    final pendingNotificationCount = pendingNotifications.length + 1;

    final notification = OfferAcceptanceGroupNotification(
      badgeCount: pendingNotificationCount,
      offerName: input.offer.name,
      data: DeviceNotificationData(
        id: notificationId,
        pendingCount: pendingNotificationCount,
      ),
    );

    final notificationItem = await saveNotificationItem(
      NotificationItem.invitationGroupAccept(
        id: notificationId,
        deviceHash: deviceHash,
        consumerAuthDid: input.authDid,
        acceptChannelDid: input.didUsedForAcceptance,
        offerLink: input.offer.offerLink,
        payload: _deviceNotificationService.getDeviceNotificationData(
          input.offer.platformType,
          notification,
        ),
      ),
    );

    await _deviceNotificationService.notify(
      platformType: input.offer.platformType,
      platformEndpointArn: input.offer.platformEndpointArn,
      notification: notification,
    );

    return notificationItem;
  }

  Future<String?> notifyFinaliseAcceptance(
    NotifyFinaliseAcceptanceInput input,
  ) async {
    late NotificationChannel? notificationChannel;

    if (input.deviceToken != null && input.platformType != null) {
      notificationChannel = await createNotificationChannel(
        CreateNotificationChannelInput(
          didUsedForAcceptance: input.didUsedForAcceptance,
          theirDid: input.theirDid,
          deviceToken: input.deviceToken!,
          platformType: input.platformType!,
        ),
        input.authDid,
      );
    }

    final notificationId = _generateNotificationItemId();

    final deviceHash = _deviceTokenMappingService.generateDeviceHash(
      input.acceptance.platformEndpointArn,
    );

    final pendingNotificationsCount =
        await _increasePendingNotificationsCountByOne(deviceHash);
    _logger.info('pending notifications: $pendingNotificationsCount');

    final offerFinalisedNotification = OfferFinalisedDeviceNotification(
      badgeCount: pendingNotificationsCount,
      data: DeviceNotificationData(
        id: notificationId,
        pendingCount: pendingNotificationsCount,
      ),
    );

    final notificationToken = notificationChannel?.notificationChannelId ?? '';

    await saveNotificationItem(
      NotificationItem.offerFinalised(
        id: notificationId,
        deviceHash: deviceHash,
        consumerAuthDid: input.authDid,
        offerLink: input.acceptance.offerLink,
        notificationToken: notificationToken,
        payload: _deviceNotificationService.getDeviceNotificationData(
          input.acceptance.platformType,
          offerFinalisedNotification,
        ),
      ),
    );

    try {
      await _deviceNotificationService.notify(
        platformType: input.acceptance.platformType,
        platformEndpointArn: input.acceptance.platformEndpointArn,
        notification: offerFinalisedNotification,
      );
    } on DeviceNotificationException {
      _logger.warn(
        'Notification failed to send for notificationId: $notificationId',
      );
      return notificationToken;
    }

    return notificationToken;
  }

  Future<void> notifyGroupMembershipFinalised(
    NotifyGroupMembershipFinalisedInput input,
  ) async {
    final deviceHash = _deviceTokenMappingService.generateDeviceHash(
      input.acceptance.platformEndpointArn,
    );

    final notificationId = _generateNotificationItemId();
    final pendingNotifications = await getPendingNotifications(deviceHash);
    final pendingNotificationCount = pendingNotifications.length + 1;

    final notification = GroupMembershipFinalisedNotification(
      badgeCount: pendingNotificationCount,
      data: DeviceNotificationData(
        id: notificationId,
        pendingCount: pendingNotificationCount,
      ),
    );

    await saveNotificationItem(
      NotificationItem.groupMembershipFinalised(
        id: notificationId,
        deviceHash: deviceHash,
        consumerAuthDid: input.authDid,
        acceptChannelDid: input.acceptOfferAsDid,
        offerLink: input.acceptance.offerLink,
        startSeqNo: input.startSeqNo,
        payload: _deviceNotificationService.getDeviceNotificationData(
          input.acceptance.platformType,
          notification,
        ),
      ),
    );

    await _deviceNotificationService.notify(
      platformType: input.acceptance.platformType,
      platformEndpointArn: input.acceptance.platformEndpointArn,
      notification: notification,
    );
  }

  Future<List<String>> deletePendingNotifications(
    String deviceHash,
    List<String> notificationIds,
  ) async {
    List<String> deletedItems = [];
    int batchSize = Config().get(
      'deviceNotification',
    )['maxPendingNotificationsToDeleteInBatch'];

    for (final notificationId in notificationIds) {
      try {
        await _storage.deleteFromlist(
          PendingNotification.entityName,
          deviceHash,
          NotificationItem.entityName,
          notificationId,
        );
        _logger.info('Notification deleted: $notificationId');
        deletedItems.add(notificationId);
      } catch (e, stackTrace) {
        _logger.error(
          'Error when deleting notification: $e',
          error: e,
          stackTrace: stackTrace,
        );
      }

      if (deletedItems.length > batchSize) {
        _logger.info('Batch size exceeded. Skip rest of pending notifiations');
        break;
      }
    }

    return deletedItems;
  }

  Future<void> deleteChannelNotification(
    String notificationToken,
    String authDid,
  ) async {
    final notificationChannel = await _storage.findOneById(
      NotificationChannel.entityName,
      notificationToken,
      NotificationChannel.fromJson,
    );

    if (notificationChannel == null) {
      throw NotificationChannelNotFound();
    }

    if (notificationChannel.createdBy != authDid) {
      throw NotAuthorizedException();
    }

    return _storage.delete(NotificationChannel.entityName, notificationToken);
  }

  Future<void> notifyOutreach(NotifyOutreachInput input, String authDid) async {
    if (input.offer.platformType == PlatformType.NONE) {
      _logger.info('Skipping outreach notification for NONE platform type');
      return;
    }

    final deviceHash = _deviceTokenMappingService.generateDeviceHash(
      input.offer.platformEndpointArn,
    );

    final notificationId = _generateNotificationItemId();
    final pendingNotifications = await getPendingNotifications(deviceHash);
    final pendingNotificationCount = pendingNotifications.length + 1;

    final notification = NotifyInvitationOutreachNotification(
      sender: input.senderInfo,
      badgeCount: pendingNotificationCount,
      data: DeviceNotificationData(
        id: notificationId,
        pendingCount: pendingNotificationCount,
      ),
    );

    await saveNotificationItem(
      NotificationItem.invitationOutreach(
        id: notificationId,
        deviceHash: deviceHash,
        consumerAuthDid: authDid,
        offerLink: input.offer.offerLink,
        payload: _deviceNotificationService.getDeviceNotificationData(
          input.offer.platformType,
          notification,
        ),
      ),
    );

    await _deviceNotificationService.notify(
      platformType: input.offer.platformType,
      platformEndpointArn: input.offer.platformEndpointArn,
      notification: notification,
    );
  }

  Future<NotificationChannel?> _queryNotificationChannel(String id) async {
    return _storage.findOneById(
      NotificationChannel.entityName,
      id,
      NotificationChannel.fromJson,
    );
  }

  String _generateNotificationChannelId({
    required String ownerDid,
    required String theirDid,
  }) {
    return generateHashedId('${ownerDid}_$theirDid', Config().hashSecret());
  }

  String _generateNotificationItemId() {
    return Uuid().v4();
  }

  Future<int> _increasePendingNotificationsCountByOne(String deviceHash) async {
    return (await getPendingNotifications(deviceHash)).length + oneMessage;
  }
}
