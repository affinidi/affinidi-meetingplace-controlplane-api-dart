// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterOfferGroupResponse _$RegisterOfferGroupResponseFromJson(
  Map<String, dynamic> json,
) => RegisterOfferGroupResponse(
  offerLink: json['offerLink'] as String,
  mnemonic: json['mnemonic'] as String,
  validUntil: json['validUntil'] as String?,
  maximumUsage: (json['maximumUsage'] as num?)?.toInt(),
  groupId: json['groupId'] as String,
  groupDid: json['groupDid'] as String,
);

Map<String, dynamic> _$RegisterOfferGroupResponseToJson(
  RegisterOfferGroupResponse instance,
) => <String, dynamic>{
  'offerLink': instance.offerLink,
  'mnemonic': instance.mnemonic,
  'validUntil': instance.validUntil,
  'maximumUsage': instance.maximumUsage,
  'groupId': instance.groupId,
  'groupDid': instance.groupDid,
};
