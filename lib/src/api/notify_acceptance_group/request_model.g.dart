// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotifyAcceptanceGroupRequest _$NotifyAcceptanceGroupRequestFromJson(
  Map<String, dynamic> json,
) => NotifyAcceptanceGroupRequest(
  mnemonic: json['mnemonic'] as String,
  offerLink: json['offerLink'] as String,
  did: json['did'] as String,
  senderInfo: json['senderInfo'] as String,
);

Map<String, dynamic> _$NotifyAcceptanceGroupRequestToJson(
  NotifyAcceptanceGroupRequest instance,
) => <String, dynamic>{
  'mnemonic': instance.mnemonic,
  'offerLink': instance.offerLink,
  'did': instance.did,
  'senderInfo': instance.senderInfo,
};
