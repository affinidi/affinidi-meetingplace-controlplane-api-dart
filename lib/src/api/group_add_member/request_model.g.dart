// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupAddMemberRequest _$GroupAddMemberRequestFromJson(
  Map<String, dynamic> json,
) => GroupAddMemberRequest(
  offerLink: json['offerLink'] as String,
  mnemonic: json['mnemonic'] as String,
  groupId: json['groupId'] as String,
  memberDid: json['memberDid'] as String,
  acceptOfferAsDid: json['acceptOfferAsDid'] as String,
  reencryptionKey: json['reencryptionKey'] as String,
  publicKey: json['publicKey'] as String,
  contactCard: json['contactCard'] as String,
);

Map<String, dynamic> _$GroupAddMemberRequestToJson(
  GroupAddMemberRequest instance,
) => <String, dynamic>{
  'offerLink': instance.offerLink,
  'mnemonic': instance.mnemonic,
  'groupId': instance.groupId,
  'memberDid': instance.memberDid,
  'acceptOfferAsDid': instance.acceptOfferAsDid,
  'reencryptionKey': instance.reencryptionKey,
  'publicKey': instance.publicKey,
  'contactCard': instance.contactCard,
};
