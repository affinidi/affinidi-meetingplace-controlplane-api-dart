import 'dart:async';

import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import 'package:mutex/mutex.dart';
import '../core/config/env_config.dart';
import '../core/config/server_config.dart';
import '../core/logger/logger.dart';
import '../core/service/device_notification/device_notification_service.dart';
import '../core/service/group/delete_group_input.dart';
import '../core/service/group/deregister_member_input.dart';
import '../core/service/group/send_message_input.dart';
import '../core/entity/group.dart';
import '../core/service/notification/notify_group_membership_finalised_input.dart';
import '../core/service/notification/notify_outreach_input.dart';
import '../core/service/offer/admin_deregister_offer_input.dart';
import '../utils/platform_type.dart';
import 'accept_offer/request_model.dart';
import 'accept_offer_group/request_model.dart';
import 'admin/deregister_offer/request_model.dart';
import 'check_offer_phrase/request_model.dart';
import 'create_oob/request_model.dart';
import 'delete_pending_notifications/request_model.dart';
import 'deregister_notification/request_model.dart';
import 'deregister_offer/request_model.dart';
import 'finalise_acceptance/request_model.dart';
import 'get_oob/request_model.dart';
import 'get_pending_notifications/request_model.dart';
import 'group_add_member/request_model.dart';
import 'group_delete/request_model.dart';
import 'group_member_deregister/request_model.dart';
import 'group_send_message/request_model.dart';
import 'notify_acceptance/request_model.dart';
import 'notify_acceptance_group/request_model.dart';
import 'notify_channel/request_model.dart';
import 'notify_outreach/request_model.dart';
import 'query_offer/request_model.dart';
import 'register_device/request_model.dart';
import 'register_notification/request_model.dart';
import 'register_offer/request_model.dart';
import 'register_offer_group/request_model.dart';
import '../core/entity/offer.dart';
import '../core/entity/oob.dart';
import '../core/service/acceptance/accept_offer_input.dart';
import '../core/service/acceptance/finalise_acceptance_input.dart';
import '../core/service/acceptance/query_acceptance_input.dart';
import '../core/service/device_mapping/register_device_input.dart';
import '../core/service/group/add_group_member_input.dart';
import '../core/service/group/create_group_input.dart';
import '../core/service/group/group_service.dart';
import '../core/service/notification/create_notification_channel_input.dart';
import '../core/service/notification/notify_acceptance_input.dart';
import '../core/service/notification/notify_channel_input.dart';
import '../core/service/offer/deregister_offer_input.dart';
import '../core/service/offer/offer_service.dart';
import '../core/service/acceptance/acceptance_service.dart';
import '../core/entity/device_token_mapping.dart';
import '../core/service/device_mapping/device_token_mapping_service.dart';
import '../core/entity/notification_channel.dart';
import '../core/entity/notification_item.dart';
import '../core/service/notification/notification_service.dart';
import '../core/service/offer/register_offer_input.dart';
import '../core/service/oob/create_oob_input.dart';
import '../core/service/oob/oob_service.dart';

class GroupCountLimitExceeded implements Exception {}

class ApplicationFacade {
  factory ApplicationFacade.init(ServerConfig config) {
    if (_instance != null) return _instance!;
    _instance = ApplicationFacade._(config: config);
    return _instance!;
  }

  ApplicationFacade._({required this.config}) {
    _logger = config.logger;

    _deviceNotificationService = DeviceNotificationService(
      logger: _logger,
      provider: config.pushNotificationProvider,
      mediatorSDK: MeetingPlaceMediatorSDK(
        mediatorDid: '',
        didResolver: config.didResolver,
      ),
    );

    _deviceTokenMappingService = DeviceTokenMappingService(config.storage);

    _notificationService = NotificationService(
      storage: config.storage,
      deviceTokenMappingService: _deviceTokenMappingService,
      deviceNotificationService: _deviceNotificationService,
      logger: _logger,
    );

    _offerService = OfferService(
      storage: config.storage,
      deviceTokenMappingService: _deviceTokenMappingService,
      logger: _logger,
    );

    _acceptanceService = AcceptanceService(
      storage: config.storage,
      offerService: _offerService,
      deviceTokenMappingService: _deviceTokenMappingService,
      notificationService: _notificationService,
      logger: _logger,
    );

    _oobService = OobService(storage: config.storage, logger: _logger);

    _groupService = GroupService(
      storage: config.storage,
      notificationService: _notificationService,
      groupDidManager: config.groupDidManager,
      didResolver: config.didResolver,
      logger: _logger,
    );
  }

  static ApplicationFacade? _instance;
  final ServerConfig config;

  late final OfferService _offerService;
  late final AcceptanceService _acceptanceService;
  late final DeviceTokenMappingService _deviceTokenMappingService;
  late final NotificationService _notificationService;
  late final OobService _oobService;
  late final GroupService _groupService;
  late final DeviceNotificationService _deviceNotificationService;
  late final Logger _logger;

  Future<Oob> createOob(CreateOobRequest request) {
    return _oobService.create(
      CreateOobInput(
        mediatorDid: request.mediatorDid,
        mediatorEndpoint: request.mediatorEndpoint,
        mediatorWSSEndpoint: request.mediatorWSSEndpoint,
        didcommMessage: request.didcommMessage,
      ),
    );
  }

  Future<Oob?> getOob(GetOobRequest request) {
    return _oobService.get(request.oobId);
  }

  Future<bool> checkOfferPhrase(CheckOfferPhraseRequest request) {
    return _offerService.isMnemonicInUse(request.offerPhrase);
  }

  Future<Offer> registerOffer(RegisterOfferRequest request, String authDid) {
    return _offerService.registerOffer(
      RegisterOfferInput(
        offerName: request.offerName,
        offerDescription: request.offerDescription,
        offerType: OfferType.chat,
        didcommMessage: request.didcommMessage,
        contactCard: request.contactCard,
        validUntil: request.validUntil,
        maximumUsage: request.maximumUsage,
        deviceToken: request.deviceToken,
        platformType: request.platformType,
        mediatorDid: request.mediatorDid,
        mediatorEndpoint: request.mediatorEndpoint,
        mediatorWSSEndpoint: request.mediatorWSSEndpoint,
        contactAttributes: request.contactAttributes,
        customPhrase: request.customPhrase,
      ),
      authDid,
    );
  }

  Future<void> deregisterOffer(DeregisterOfferRequest request, String authDid) {
    return _offerService.deregisterOffer(
      DeregisterOfferInput(
        offerLink: request.offerLink,
        mnemonic: request.mnemonic,
      ),
      authDid,
    );
  }

  Future<void> deregisterOfferAsAdmin(
    AdminDeregisterOfferRequest request,
    String authDid,
  ) {
    return _offerService.deregisterOfferAsAdmin(
      AdminDeregisterOfferInput(mnemonic: request.mnemonic),
      authDid,
    );
  }

  Future<(Offer, Group)> registerOfferGroup(
    RegisterOfferGroupRequest request,
    String authDid,
  ) async {
    final lock = Mutex();
    try {
      await lock.acquire();

      final groupCount = await _groupService.countGroups();
      if (groupCount >= int.parse(getEnv('GROUP_COUNT_LIMIT'))) {
        throw GroupCountLimitExceeded();
      }

      final deviceTokenMapping = await _deviceTokenMappingService
          .getDeviceTokenMapping(
            devicePlatform: request.platformType,
            deviceToken: request.deviceToken,
          );

      final offer = await _offerService.registerOffer(
        RegisterOfferInput(
          offerName: request.offerName,
          offerDescription: request.offerDescription,
          offerType: OfferType.group,
          customPhrase: request.customPhrase,
          didcommMessage: request.didcommMessage,
          contactCard: request.contactCard,
          validUntil: request.validUntil,
          maximumUsage: request.maximumUsage,
          mediatorDid: request.mediatorDid,
          mediatorEndpoint: request.mediatorEndpoint,
          mediatorWSSEndpoint: request.mediatorWSSEndpoint,
          contactAttributes: 64,
          deviceToken: request.deviceToken,
          platformType: request.platformType,
          metadata: request.metadata,
        ),
        authDid,
      );

      final group = await _groupService.createGroup(
        CreateGroupInput(
          offerLink: offer.offerLink,
          groupName: request.offerName,
          controllingDid: authDid,
          mediatorDid: request.mediatorDid,
          createdBy: authDid,
          modifiedBy: authDid,
        ),
      );

      await _groupService.addMemberToGroup(
        AddGroupMemberInput(
          groupId: group.id,
          offerLink: offer.offerLink,
          memberDid: request.adminDid,
          memberPublicKey: request.adminPublicKey,
          memberReencryptionKey: request.adminReencryptionKey,
          memberContactCard: request.memberContactCard,
          platformType: request.platformType,
          platformEndpointArn: deviceTokenMapping.platformEndpointArn,
          controllingDid: authDid,
          authDid: authDid,
        ),
      );

      offer.groupId = group.id;
      offer.groupDid = group.groupDid;

      await _offerService.updateOffer(offer);

      lock.release();
      return (offer, group);
    } catch (e) {
      lock.release();
      rethrow;
    }
  }

  Future<Offer?> queryOffer(QueryOfferRequest request, String authDid) async {
    return _offerService.queryOfferByMnemonic(
      OfferAccessType.query,
      request.mnemonic,
    );
  }

  Future<Offer> acceptOffer(AcceptOfferRequest request, String authDid) async {
    return _acceptanceService.acceptOffer(
      AcceptOfferInput(
        acceptOfferAsDid: request.did,
        mnemonic: request.mnemonic,
        deviceToken: request.deviceToken,
        platformType: request.platformType,
        contactCard: request.contactCard,
      ),
      authDid,
    );
  }

  Future<Offer> acceptOfferGroup(
    AcceptOfferGroupRequest request,
    String authDid,
  ) async {
    return _acceptanceService.acceptOffer(
      AcceptOfferInput(
        acceptOfferAsDid: request.did,
        mnemonic: request.mnemonic,
        deviceToken: request.deviceToken,
        platformType: request.platformType,
        contactCard: request.contactCard,
      ),
      authDid,
    );
  }

  Future<String?> finaliseAcceptance(
    FinaliseAcceptanceRequest request,
    String authDid,
  ) async {
    return _acceptanceService.finaliseAcceptance(
      FinaliseAcceptanceInput(
        mnemonic: request.mnemonic,
        offerLink: request.offerLink,
        didUsedForAcceptance: request.did,
        theirDid: request.theirDid,
        deviceToken: request.deviceToken,
        platformType: request.platformType,
      ),
      authDid,
    );
  }

  Future<DeviceTokenMapping> registerDevice(
    RegisterDeviceRequest request,
    String authDid,
  ) async {
    if (request.platformType == PlatformType.DIDCOMM) {
      return _deviceTokenMappingService.createMapping(
        RegisterDeviceInput(
          deviceToken: request.deviceToken,
          platformType: request.platformType,
          platformEndpointArn: request.deviceToken,
        ),
        authDid,
      );
    }

    final platformRegistration = await _deviceNotificationService
        .attemptPlatformRegistration(
          platformType: request.platformType,
          deviceToken: request.deviceToken,
          consumerDid: authDid,
        );

    return _deviceTokenMappingService.createMapping(
      RegisterDeviceInput(
        deviceToken: request.deviceToken,
        platformType: request.platformType,
        platformEndpointArn: platformRegistration,
      ),
      authDid,
    );
  }

  Future<NotificationChannel> registerNotification(
    RegisterNotificationRequest input,
    String authDid,
  ) async {
    return _notificationService.createNotificationChannel(
      CreateNotificationChannelInput(
        didUsedForAcceptance: input.myDid,
        theirDid: input.theirDid,
        deviceToken: input.deviceToken,
        platformType: input.platformType,
      ),
      authDid,
    );
  }

  Future<NotificationItem> notifyChannel(
    NotifyChannelRequest request,
    String authDid,
  ) async {
    return _notificationService.notifyChannel(
      NotifyChannelInput(
        notificationChannelId: request.notificationChannelId,
        did: request.did,
        type: request.type,
      ),
      authDid,
    );
  }

  Future<NotificationItem> notifyAcceptance(
    NotifyAcceptanceRequest request,
    String authDid,
  ) async {
    final offer = await _offerService.queryOfferByMnemonic(
      OfferAccessType.queryNoLimits,
      request.mnemonic,
    );

    if (offer == null) {
      throw OfferNotFound(mnemonic: request.mnemonic);
    }

    final acceptance = await _acceptanceService.queryAcceptance(
      QueryAcceptanceInput(
        mnemonic: request.mnemonic,
        didUsedForAcceptance: request.did,
        offerLink: request.offerLink,
      ),
    );

    return _notificationService.notifyAcceptance(
      NotifyAcceptanceInput(
        offer: offer,
        acceptance: acceptance,
        didUsedForAcceptance: request.did,
        senderInfo: request.senderInfo,
        authDid: authDid,
      ),
    );
  }

  Future<NotificationItem> notifyAcceptanceGroup(
    NotifyAcceptanceGroupRequest request,
    String authDid,
  ) async {
    final offer = await _offerService.queryOfferByMnemonic(
      OfferAccessType.queryNoLimits,
      request.mnemonic,
    );

    if (offer == null) {
      throw OfferNotFound(mnemonic: request.mnemonic);
    }

    final acceptance = await _acceptanceService.queryAcceptance(
      QueryAcceptanceInput(
        mnemonic: request.mnemonic,
        didUsedForAcceptance: request.did,
        offerLink: request.offerLink,
      ),
    );

    return _notificationService.notifyAcceptanceGroup(
      NotifyAcceptanceInput(
        offer: offer,
        acceptance: acceptance,
        didUsedForAcceptance: request.did,
        senderInfo: request.senderInfo,
        authDid: authDid,
      ),
    );
  }

  Future<List<NotificationItem>> getPendingNotifications(
    GetPendingNotificationsRequest request,
  ) async {
    final deviceTokenMapping = await _deviceTokenMappingService
        .getDeviceTokenMapping(
          devicePlatform: request.platformType,
          deviceToken: request.deviceToken,
        );

    _logger.info('device token mapping found:');
    _logger.info('- [endpoint] ${deviceTokenMapping.platformEndpointArn}');
    _logger.info('- [platform type] ${deviceTokenMapping.platformType}');

    final deviceHash = _deviceTokenMappingService.generateDeviceHash(
      deviceTokenMapping.platformEndpointArn,
    );

    return _notificationService.getPendingNotifications(deviceHash);
  }

  Future<Map> deletePendingNotifications(
    DeletePendingNotificationsRequest request,
  ) async {
    final deviceTokenMapping = await _deviceTokenMappingService
        .getDeviceTokenMapping(
          devicePlatform: request.platformType,
          deviceToken: request.deviceToken,
        );

    String deviceHash = _deviceTokenMappingService.generateDeviceHash(
      deviceTokenMapping.platformEndpointArn,
    );

    final deletedNotificationIds = await _notificationService
        .deletePendingNotifications(deviceHash, request.notificationIds);

    final remainingNotifications = await _notificationService
        .getPendingNotifications(deviceHash);
    _logger.info(
      '''There are ${remainingNotifications.length} outstanding notifications for target device''',
    );

    return {
      'deletedNotificationIds': deletedNotificationIds,
      'remainingNotifications': remainingNotifications,
    };
  }

  Future<void> deregisterNotification(
    DeregisterNotificationRequest request,
    String authDid,
  ) {
    return _notificationService.deleteChannelNotification(
      request.notificationToken,
      authDid,
    );
  }

  Future<void> addMemberToGroup(
    GroupAddMemberRequest request,
    String authDid,
  ) async {
    final acceptance = await _acceptanceService.queryAcceptance(
      QueryAcceptanceInput(
        mnemonic: request.mnemonic,
        didUsedForAcceptance: request.acceptOfferAsDid,
        offerLink: request.offerLink,
      ),
    );

    await _groupService.addMemberToGroup(
      AddGroupMemberInput(
        groupId: request.groupId,
        offerLink: request.offerLink,
        memberDid: request.memberDid,
        memberPublicKey: request.publicKey,
        memberReencryptionKey: request.reencryptionKey,
        memberContactCard: request.contactCard,
        platformType: acceptance.platformType,
        platformEndpointArn: acceptance.platformEndpointArn,
        controllingDid: acceptance.createdBy,
        authDid: authDid,
      ),
    );

    final group = await _groupService.getGroup(request.groupId);
    await _notificationService.notifyGroupMembershipFinalised(
      NotifyGroupMembershipFinalisedInput(
        acceptance: acceptance,
        acceptOfferAsDid: request.acceptOfferAsDid,
        authDid: authDid,
        startSeqNo: group.seqNo,
      ),
    );
  }

  Future<void> sendGroupMessage(GroupSendMessage request, String authDid) {
    return _groupService.sendMessage(
      SendMessageInput(
        offerLink: request.offerLink,
        groupDid: request.groupDid,
        controllingDid: authDid,
        messagePayload: request.payload,
        incSeqNo: request.incSeqNo,
        notify: request.notify,
      ),
    );
  }

  Future<void> deregisterMemberFromGroup(
    GroupMemberDeregisterRequest request,
    String authDid,
  ) async {
    return _groupService.deregisterMember(
      DeregisterMemberInput(
        groupId: request.groupId,
        controllingDid: authDid,
        messageToRelay: request.messageToRelay,
      ),
    );
  }

  Future<void> deleteGroup(GroupDeleteRequest request, String authDid) async {
    await _groupService.deleteGroup(
      DeleteGroupInput(
        groupId: request.groupId,
        messageToRelay: request.messageToRelay,
        controllingDid: authDid,
      ),
    );
  }

  Future<void> notifyOutreach(
    NotifyOutreachRequest request,
    String authDid,
  ) async {
    final offer = await _offerService.queryOfferByMnemonic(
      OfferAccessType.queryNoLimits,
      request.mnemonic,
    );

    if (offer == null) throw OfferNotFound(mnemonic: request.mnemonic);

    return _notificationService.notifyOutreach(
      NotifyOutreachInput(offer: offer, senderInfo: request.senderInfo),
      authDid,
    );
  }

  Future<List<Offer>> updateOffersVrcCount(
    int score,
    List<String> offerLinks,
  ) async {
    final List<Offer> updated = [];
    for (final link in offerLinks) {
      Offer? offer = await _offerService.getOfferByLink(link);
      if (offer != null) {
        offer.vrcCount = score;
        await _offerService.updateOffer(offer);
        updated.add(offer);
      }
    }
    return updated;
  }

  logInfo(String message) => _logger.info(message);

  logError(
    String message, {
    required Object error,
    required StackTrace stackTrace,
  }) => _logger.error(message, error: error, stackTrace: stackTrace);
}
