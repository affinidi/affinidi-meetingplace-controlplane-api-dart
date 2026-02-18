import 'dart:convert';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import 'package:uuid/uuid.dart';

import '../../../../../meeting_place_control_plane_api.dart';
import '../../../../service/did_resolver/custom_did_resolver.dart';
import '../../../logger/logger.dart';
import '../../auth/auth_did_manager.dart';
import '../../auth/didcomm_auth_builder.dart';
import '../device_notification.dart';
import '../device_notification_service.dart';
import '../../../entity/notification_item.dart';
import 'platform.dart';

enum DidCommMessageType {
  invitationAcceptance,
  invitationAcceptanceGroup,
  outreachInvitation,
  connectionRequestApproval,
  channelActivity,
  groupMembershipFinalised;

  String get value {
    switch (this) {
      case DidCommMessageType.invitationAcceptance:
        return MeetingPlaceNotificationProtocol.invitationAcceptance.value;
      case DidCommMessageType.invitationAcceptanceGroup:
        return MeetingPlaceNotificationProtocol.invitationAcceptanceGroup.value;
      case DidCommMessageType.outreachInvitation:
        return MeetingPlaceNotificationProtocol.outreachInvitation.value;
      case DidCommMessageType.connectionRequestApproval:
        return MeetingPlaceNotificationProtocol.connectionRequestApproval.value;
      case DidCommMessageType.channelActivity:
        return MeetingPlaceNotificationProtocol.channelActivity.value;
      case DidCommMessageType.groupMembershipFinalised:
        return MeetingPlaceNotificationProtocol.groupMembershipFinalised.value;
    }
  }
}

const _notificationTypeToMessageType = {
  NotificationItemType.invitationAccept:
      DidCommMessageType.invitationAcceptance,
  NotificationItemType.invitationGroupAccept:
      DidCommMessageType.invitationAcceptanceGroup,
  NotificationItemType.offerFinalised:
      DidCommMessageType.connectionRequestApproval,
  NotificationItemType.channelActivity: DidCommMessageType.channelActivity,
  NotificationItemType.groupMembershipFinalised:
      DidCommMessageType.groupMembershipFinalised,
  NotificationItemType.invitationOutreach:
      DidCommMessageType.outreachInvitation,
};

DidCommMessageType didCommMessageTypeForNotificationType(
  NotificationItemType type,
) {
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
      type: Uri.parse(didCommMessageTypeForNotificationType(type).value),
      createdTime: DateTime.now().toUtc(),
      body: {...data.toJson(), 'text': body},
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
  }) : _logger = logger,
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
    final authDidManager = await AuthDidManager.getInstance(
      jwks: didcommAuth.jwk,
    );
    final senderDidDoc = await authDidManager.didManager.getDidDocument();

    final recipientDidDoc = await CustomDidResolver().resolveDid(recipientDid);
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
  DidCommPayload getPayload(DeviceNotification notification) {
    return DidCommPayload(
      type: notification.notificationType,
      threadId: notification.threadId,
      body: notification.getBody(),
      data: notification.data,
    );
  }
}
