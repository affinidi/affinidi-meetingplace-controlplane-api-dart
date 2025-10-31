import 'dart:convert';

import 'entity.dart';
import '../service/device_notification/device_notification.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'notification_item.g.dart';

enum NotificationItemType {
  offerFinalised('OfferFinalised'),
  invitationAccept('InvitationAccept'),
  invitationGroupAccept('InvitationGroupAccept'),
  invitationOutreach('InvitationOutreach'),
  groupMembershipFinalised('GroupMembershipFinalised'),
  channelActivity('ChannelActivity');

  const NotificationItemType(this.value);

  final String value;
}

abstract class NotificationItemPayload {
  NotificationItemPayload({
    required this.id,
    required this.notificationDate,
    required this.pendingCount,
  });
  final String id;
  final String notificationDate;
  final int pendingCount;
}

@JsonSerializable()
class InvitationAcceptPayload extends NotificationItemPayload {
  InvitationAcceptPayload({
    required super.id,
    required super.notificationDate,
    required super.pendingCount,
    required this.offerLink,
    required this.did,
  });
  final String offerLink;
  final String did;

  @override
  String toString() => JsonEncoder().convert({
        'type': NotificationItemType.invitationAccept.value,
        'data': _$InvitationAcceptPayloadToJson(this),
      });
}

@JsonSerializable()
class InvitationGroupAcceptPayload extends NotificationItemPayload {
  InvitationGroupAcceptPayload({
    required super.id,
    required super.notificationDate,
    required super.pendingCount,
    required this.offerLink,
    required this.did,
  });
  final String offerLink;
  final String did;

  @override
  String toString() => JsonEncoder().convert({
        'type': NotificationItemType.invitationGroupAccept.value,
        'data': _$InvitationGroupAcceptPayloadToJson(this),
      });
}

@JsonSerializable()
class GroupMembershipFinalisedPayload extends NotificationItemPayload {
  GroupMembershipFinalisedPayload({
    required super.id,
    required super.notificationDate,
    required super.pendingCount,
    required this.offerLink,
    required this.startSeqNo,
  });
  final String offerLink;
  final int startSeqNo;

  @override
  String toString() => JsonEncoder().convert({
        'type': NotificationItemType.groupMembershipFinalised.value,
        'data': _$GroupMembershipFinalisedPayloadToJson(this),
      });
}

@JsonSerializable()
class InvitationOutreachPayload extends NotificationItemPayload {
  InvitationOutreachPayload({
    required super.id,
    required super.notificationDate,
    required super.pendingCount,
    required this.offerLink,
  });
  final String offerLink;

  @override
  String toString() => JsonEncoder().convert({
        'type': NotificationItemType.invitationOutreach.value,
        'data': _$InvitationOutreachPayloadToJson(this),
      });
}

@JsonSerializable()
class ChannelActivityPayload extends NotificationItemPayload {
  ChannelActivityPayload({
    required super.id,
    required super.notificationDate,
    required super.pendingCount,
    required this.did,
    required this.type,
  });
  final String did;
  final String type;

  @override
  String toString() => JsonEncoder().convert({
        'type': NotificationItemType.channelActivity.value,
        'data': _$ChannelActivityPayloadToJson(this),
      });
}

@JsonSerializable()
class OfferFinalisedPayload extends NotificationItemPayload {
  OfferFinalisedPayload({
    required super.id,
    required super.notificationDate,
    required super.pendingCount,
    required this.offerLink,
    required this.notificationToken,
  });
  final String offerLink;
  final String notificationToken;

  @override
  String toString() => JsonEncoder().convert({
        'type': NotificationItemType.offerFinalised.value,
        'data': _$OfferFinalisedPayloadToJson(this),
      });
}

@JsonSerializable()
class NotificationItem extends Entity {
  NotificationItem({
    required this.id,
    required this.type,
    required this.deviceHash,
    required this.consumerAuthDid,
    required this.payload,
    this.offerLink,
    this.acceptChannelDid,
  }) {
    createdAt = DateTime.now().toIso8601String();
  }

  factory NotificationItem.invitationAccept({
    required String id,
    required String deviceHash,
    required String consumerAuthDid,
    required String acceptChannelDid,
    required String offerLink,
    required DeviceNotificationData payload,
  }) =>
      NotificationItem(
        id: id,
        type: NotificationItemType.invitationAccept,
        deviceHash: deviceHash,
        consumerAuthDid: consumerAuthDid,
        acceptChannelDid: acceptChannelDid,
        payload: InvitationAcceptPayload(
          id: id,
          notificationDate: payload.notificationDate,
          pendingCount: payload.pendingCount,
          offerLink: offerLink,
          did: acceptChannelDid,
        ).toString(),
      );

  factory NotificationItem.invitationGroupAccept({
    required String id,
    required String deviceHash,
    required String consumerAuthDid,
    required String acceptChannelDid,
    required String offerLink,
    required DeviceNotificationData payload,
  }) =>
      NotificationItem(
        id: id,
        type: NotificationItemType.invitationGroupAccept,
        deviceHash: deviceHash,
        consumerAuthDid: consumerAuthDid,
        acceptChannelDid: acceptChannelDid,
        payload: InvitationGroupAcceptPayload(
          id: id,
          notificationDate: payload.notificationDate,
          pendingCount: payload.pendingCount,
          offerLink: offerLink,
          did: acceptChannelDid,
        ).toString(),
      );

  factory NotificationItem.groupMembershipFinalised({
    required String id,
    required String deviceHash,
    required String consumerAuthDid,
    required String acceptChannelDid,
    required String offerLink,
    required int startSeqNo,
    required DeviceNotificationData payload,
  }) =>
      NotificationItem(
        id: id,
        type: NotificationItemType.groupMembershipFinalised,
        deviceHash: deviceHash,
        consumerAuthDid: consumerAuthDid,
        acceptChannelDid: acceptChannelDid,
        payload: GroupMembershipFinalisedPayload(
          id: id,
          notificationDate: payload.notificationDate,
          pendingCount: payload.pendingCount,
          offerLink: offerLink,
          startSeqNo: startSeqNo,
        ).toString(),
      );

  factory NotificationItem.channelActivity({
    required String id,
    required String type,
    required String deviceHash,
    required String consumerAuthDid,
    required String acceptChannelDid,
    required DeviceNotificationData payload,
  }) =>
      NotificationItem(
        id: id,
        type: NotificationItemType.channelActivity,
        deviceHash: deviceHash,
        consumerAuthDid: consumerAuthDid,
        acceptChannelDid: acceptChannelDid,
        payload: ChannelActivityPayload(
          id: payload.id,
          notificationDate: payload.notificationDate,
          pendingCount: payload.pendingCount,
          did: acceptChannelDid,
          type: type,
        ).toString(),
      );

  factory NotificationItem.offerFinalised({
    required String id,
    required String deviceHash,
    required String consumerAuthDid,
    required String offerLink,
    required String notificationToken,
    required DeviceNotificationData payload,
  }) =>
      NotificationItem(
        id: id,
        type: NotificationItemType.offerFinalised,
        deviceHash: deviceHash,
        consumerAuthDid: consumerAuthDid,
        payload: OfferFinalisedPayload(
          id: payload.id,
          notificationDate: payload.notificationDate,
          pendingCount: payload.pendingCount,
          offerLink: offerLink,
          notificationToken: notificationToken,
        ).toString(),
      );

  factory NotificationItem.invitationOutreach({
    required String id,
    required String deviceHash,
    required String consumerAuthDid,
    required String offerLink,
    required DeviceNotificationData payload,
  }) =>
      NotificationItem(
        id: id,
        type: NotificationItemType.invitationOutreach,
        deviceHash: deviceHash,
        consumerAuthDid: consumerAuthDid,
        payload: InvitationOutreachPayload(
          id: id,
          notificationDate: payload.notificationDate,
          pendingCount: payload.pendingCount,
          offerLink: offerLink,
        ).toString(),
      );

  @override
  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      _$NotificationItemFromJson(json);
  static String entityName = 'NotificationItem';

  final String id;
  final NotificationItemType type;
  final String deviceHash;
  final String consumerAuthDid;
  final String payload;
  final String? offerLink;
  final String? acceptChannelDid;

  late String createdAt;

  @override
  Map<String, dynamic> toJson() => _$NotificationItemToJson(this);

  @override
  String getId() => id;

  @override
  String getEntityName() => entityName;

  @override
  String getListId() => deviceHash;

  static String generateId() => Uuid().v4();
}
