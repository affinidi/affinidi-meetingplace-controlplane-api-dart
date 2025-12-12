// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_group_member_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddGroupMemberInput _$AddGroupMemberInputFromJson(Map<String, dynamic> json) =>
    AddGroupMemberInput(
      groupId: json['groupId'] as String,
      offerLink: json['offerLink'] as String,
      memberDid: json['memberDid'] as String,
      memberPublicKey: json['memberPublicKey'] as String,
      memberReencryptionKey: json['memberReencryptionKey'] as String,
      memberVCard: json['memberVCard'] as String,
      platformType: $enumDecode(_$PlatformTypeEnumMap, json['platformType']),
      platformEndpointArn: json['platformEndpointArn'] as String,
      controllingDid: json['controllingDid'] as String,
      authDid: json['authDid'] as String,
    );

Map<String, dynamic> _$AddGroupMemberInputToJson(
  AddGroupMemberInput instance,
) => <String, dynamic>{
  'groupId': instance.groupId,
  'offerLink': instance.offerLink,
  'memberDid': instance.memberDid,
  'memberPublicKey': instance.memberPublicKey,
  'memberReencryptionKey': instance.memberReencryptionKey,
  'memberVCard': instance.memberVCard,
  'platformType': _$PlatformTypeEnumMap[instance.platformType]!,
  'platformEndpointArn': instance.platformEndpointArn,
  'controllingDid': instance.controllingDid,
  'authDid': instance.authDid,
};

const _$PlatformTypeEnumMap = {
  PlatformType.DIDCOMM: 'DIDCOMM',
  PlatformType.PUSH_NOTIFICATION: 'PUSH_NOTIFICATION',
  PlatformType.NONE: 'NONE',
};
