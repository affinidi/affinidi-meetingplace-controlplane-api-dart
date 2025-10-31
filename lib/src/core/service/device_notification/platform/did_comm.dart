import 'dart:convert';
import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import 'package:uuid/uuid.dart';

import '../../../config/config.dart';
import '../../../config/env_config.dart';
import '../../../../service/did_resolver/cached_did_resolver.dart';
import '../../../logger/logger.dart';
import '../../auth/auth_did_manager.dart';
import '../../auth/didcomm_auth_builder.dart';
import '../device_notification.dart';
import '../device_notification_service.dart';
import '../../../entity/notification_item.dart';
import 'platform.dart';

enum DidCommMessageType {
  invitationAccept('invitation-accept'),
  invitationGroupAccept('invitation-accept-group'),
  invitationOutreach('invitation-outreach'),
  offerFinalised('offer-finalised'),
  channelActivity('channel-activity'),
  groupMembershipFinalised('group-membership-finalised');

  const DidCommMessageType(this.value);

  final String value;
}

const _notificationTypeToMessageType = {
  NotificationItemType.invitationAccept: DidCommMessageType.invitationAccept,
  NotificationItemType.invitationGroupAccept:
      DidCommMessageType.invitationGroupAccept,
  NotificationItemType.offerFinalised: DidCommMessageType.offerFinalised,
  NotificationItemType.channelActivity: DidCommMessageType.channelActivity,
  NotificationItemType.groupMembershipFinalised:
      DidCommMessageType.groupMembershipFinalised,
  NotificationItemType.invitationOutreach:
      DidCommMessageType.invitationOutreach,
};

DidCommMessageType didCommMessageTypeForNotificationType(
    NotificationItemType type) {
  return _notificationTypeToMessageType[type] ??
      (throw Exception('Unsupported notification item type: ${type.name}'));
}

class DidCommPayload implements IPayload {
  DidCommPayload({
    required this.type,
    required this.body,
    required this.threadId,
    required this.data,
  });
  final NotificationItemType type;
  final String body;
  final String threadId;
  final DeviceNotificationData data;

  @override
  String build() {
    final didcommMessage = PlainTextMessage(
      id: Uuid().v4(),
      type: Uri.parse(
          '''${getEnv('CONTROL_PLANE_DID')}/mpx/control-plane/${didCommMessageTypeForNotificationType(type).value}'''),
      createdTime: DateTime.now().toUtc(),
      body: {
        ...data.toJson(),
        'text': body,
      },
    );
    return jsonEncode(didcommMessage.toJson());
  }

  @override
  DeviceNotificationData getData() {
    return data;
  }
}

class DidComm extends Platform implements IPlatform {
  DidComm({
    required MeetingPlaceMediatorSDK mediatorSDK,
    required Logger logger,
  })  : _logger = logger,
        _mediatorSDK = mediatorSDK;

  final Logger _logger;
  final MeetingPlaceMediatorSDK _mediatorSDK;

  @override
  Future<DeviceNotificationData> notify({
    required String platformEndpointArn,
    required DeviceNotification notification,
  }) async {
    final parts = platformEndpointArn.split('::');
    final mediatorDid = parts.first;
    final recipientDid = parts[1];

    final payload = getPayload(notification);

    final didcommAuth = await DIDCommAuthBuilder(logger: _logger).build();
    final authDidManager =
        await AuthDidManager.getInstance(jwks: didcommAuth.jwk);
    final senderDidDoc = await authDidManager.didManager.getDidDocument();

    final recipientDidDoc = await CachedDidResolver().resolveDid(recipientDid);
    await _mediatorSDK.sendMessage(
      PlainTextMessage.fromJson({
        ...jsonDecode(payload.build()),
        'from': senderDidDoc.id,
        'to': [recipientDidDoc.id],
      }),
      senderDidManager: authDidManager.didManager,
      recipientDidDocument: recipientDidDoc,
      mediatorDid: mediatorDid,
    );

    _logger.info('notification sent');
    return payload.getData();
  }

  @override
  String getPlatformArn() {
    return Config().get('deviceNotification')['platformArns']['FCM'];
  }

  @override
  DidCommPayload getPayload(DeviceNotification notification) {
    return DidCommPayload(
      type: notification.notificationType,
      threadId: notification.threadId,
      body: notification.getBody(),
      data: notification.data,
    );
  }
}
