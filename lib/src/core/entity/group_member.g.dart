// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupMember _$GroupMemberFromJson(Map<String, dynamic> json) => GroupMember(
  groupId: json['groupId'] as String,
  offerLink: json['offerLink'] as String,
  memberDid: json['memberDid'] as String,
  memberPublicKey: json['memberPublicKey'] as String,
  memberReencryptionKey: json['memberReencryptionKey'] as String,
  memberVCard: json['memberVCard'] as String,
  platformEndpointArn: json['platformEndpointArn'] as String,
  platformType: $enumDecode(_$PlatformTypeEnumMap, json['platformType']),
  controllingDid: json['controllingDid'] as String,
  startSeqNo: (json['startSeqNo'] as num).toInt(),
  ttl: json['ttl'] == null ? null : DateTime.parse(json['ttl'] as String),
);

Map<String, dynamic> _$GroupMemberToJson(GroupMember instance) =>
    <String, dynamic>{
      'ttl': instance.ttl?.toIso8601String(),
      'groupId': instance.groupId,
      'offerLink': instance.offerLink,
      'memberDid': instance.memberDid,
      'memberPublicKey': instance.memberPublicKey,
      'memberReencryptionKey': instance.memberReencryptionKey,
      'memberVCard': instance.memberVCard,
      'platformEndpointArn': instance.platformEndpointArn,
      'platformType': _$PlatformTypeEnumMap[instance.platformType]!,
      'controllingDid': instance.controllingDid,
      'startSeqNo': instance.startSeqNo,
    };

const _$PlatformTypeEnumMap = {
  PlatformType.DIDCOMM: 'DIDCOMM',
  PlatformType.PUSH_NOTIFICATION: 'PUSH_NOTIFICATION',
  PlatformType.NONE: 'NONE',
};
