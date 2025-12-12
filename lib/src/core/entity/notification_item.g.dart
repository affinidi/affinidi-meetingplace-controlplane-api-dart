// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvitationAcceptPayload _$InvitationAcceptPayloadFromJson(
  Map<String, dynamic> json,
) => InvitationAcceptPayload(
  id: json['id'] as String,
  notificationDate: json['notificationDate'] as String,
  pendingCount: (json['pendingCount'] as num).toInt(),
  offerLink: json['offerLink'] as String,
  did: json['did'] as String,
);

Map<String, dynamic> _$InvitationAcceptPayloadToJson(
  InvitationAcceptPayload instance,
) => <String, dynamic>{
  'id': instance.id,
  'notificationDate': instance.notificationDate,
  'pendingCount': instance.pendingCount,
  'offerLink': instance.offerLink,
  'did': instance.did,
};

InvitationGroupAcceptPayload _$InvitationGroupAcceptPayloadFromJson(
  Map<String, dynamic> json,
) => InvitationGroupAcceptPayload(
  id: json['id'] as String,
  notificationDate: json['notificationDate'] as String,
  pendingCount: (json['pendingCount'] as num).toInt(),
  offerLink: json['offerLink'] as String,
  did: json['did'] as String,
);

Map<String, dynamic> _$InvitationGroupAcceptPayloadToJson(
  InvitationGroupAcceptPayload instance,
) => <String, dynamic>{
  'id': instance.id,
  'notificationDate': instance.notificationDate,
  'pendingCount': instance.pendingCount,
  'offerLink': instance.offerLink,
  'did': instance.did,
};

GroupMembershipFinalisedPayload _$GroupMembershipFinalisedPayloadFromJson(
  Map<String, dynamic> json,
) => GroupMembershipFinalisedPayload(
  id: json['id'] as String,
  notificationDate: json['notificationDate'] as String,
  pendingCount: (json['pendingCount'] as num).toInt(),
  offerLink: json['offerLink'] as String,
  startSeqNo: (json['startSeqNo'] as num).toInt(),
);

Map<String, dynamic> _$GroupMembershipFinalisedPayloadToJson(
  GroupMembershipFinalisedPayload instance,
) => <String, dynamic>{
  'id': instance.id,
  'notificationDate': instance.notificationDate,
  'pendingCount': instance.pendingCount,
  'offerLink': instance.offerLink,
  'startSeqNo': instance.startSeqNo,
};

InvitationOutreachPayload _$InvitationOutreachPayloadFromJson(
  Map<String, dynamic> json,
) => InvitationOutreachPayload(
  id: json['id'] as String,
  notificationDate: json['notificationDate'] as String,
  pendingCount: (json['pendingCount'] as num).toInt(),
  offerLink: json['offerLink'] as String,
);

Map<String, dynamic> _$InvitationOutreachPayloadToJson(
  InvitationOutreachPayload instance,
) => <String, dynamic>{
  'id': instance.id,
  'notificationDate': instance.notificationDate,
  'pendingCount': instance.pendingCount,
  'offerLink': instance.offerLink,
};

ChannelActivityPayload _$ChannelActivityPayloadFromJson(
  Map<String, dynamic> json,
) => ChannelActivityPayload(
  id: json['id'] as String,
  notificationDate: json['notificationDate'] as String,
  pendingCount: (json['pendingCount'] as num).toInt(),
  did: json['did'] as String,
  type: json['type'] as String,
);

Map<String, dynamic> _$ChannelActivityPayloadToJson(
  ChannelActivityPayload instance,
) => <String, dynamic>{
  'id': instance.id,
  'notificationDate': instance.notificationDate,
  'pendingCount': instance.pendingCount,
  'did': instance.did,
  'type': instance.type,
};

OfferFinalisedPayload _$OfferFinalisedPayloadFromJson(
  Map<String, dynamic> json,
) => OfferFinalisedPayload(
  id: json['id'] as String,
  notificationDate: json['notificationDate'] as String,
  pendingCount: (json['pendingCount'] as num).toInt(),
  offerLink: json['offerLink'] as String,
  notificationToken: json['notificationToken'] as String,
);

Map<String, dynamic> _$OfferFinalisedPayloadToJson(
  OfferFinalisedPayload instance,
) => <String, dynamic>{
  'id': instance.id,
  'notificationDate': instance.notificationDate,
  'pendingCount': instance.pendingCount,
  'offerLink': instance.offerLink,
  'notificationToken': instance.notificationToken,
};

NotificationItem _$NotificationItemFromJson(Map<String, dynamic> json) =>
    NotificationItem(
        id: json['id'] as String,
        type: $enumDecode(_$NotificationItemTypeEnumMap, json['type']),
        deviceHash: json['deviceHash'] as String,
        consumerAuthDid: json['consumerAuthDid'] as String,
        payload: json['payload'] as String,
        offerLink: json['offerLink'] as String?,
        acceptChannelDid: json['acceptChannelDid'] as String?,
      )
      ..ttl = json['ttl'] == null ? null : DateTime.parse(json['ttl'] as String)
      ..createdAt = json['createdAt'] as String;

Map<String, dynamic> _$NotificationItemToJson(NotificationItem instance) =>
    <String, dynamic>{
      'ttl': instance.ttl?.toIso8601String(),
      'id': instance.id,
      'type': _$NotificationItemTypeEnumMap[instance.type]!,
      'deviceHash': instance.deviceHash,
      'consumerAuthDid': instance.consumerAuthDid,
      'payload': instance.payload,
      'offerLink': instance.offerLink,
      'acceptChannelDid': instance.acceptChannelDid,
      'createdAt': instance.createdAt,
    };

const _$NotificationItemTypeEnumMap = {
  NotificationItemType.offerFinalised: 'offerFinalised',
  NotificationItemType.invitationAccept: 'invitationAccept',
  NotificationItemType.invitationGroupAccept: 'invitationGroupAccept',
  NotificationItemType.invitationOutreach: 'invitationOutreach',
  NotificationItemType.groupMembershipFinalised: 'groupMembershipFinalised',
  NotificationItemType.channelActivity: 'channelActivity',
};
