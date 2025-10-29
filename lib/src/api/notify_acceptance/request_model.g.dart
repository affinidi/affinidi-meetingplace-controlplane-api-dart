// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotifyAcceptanceRequest _$NotifyAcceptanceRequestFromJson(
        Map<String, dynamic> json) =>
    NotifyAcceptanceRequest(
      mnemonic: json['mnemonic'] as String,
      offerLink: json['offerLink'] as String,
      did: json['did'] as String,
      senderInfo: json['senderInfo'] as String,
    );

Map<String, dynamic> _$NotifyAcceptanceRequestToJson(
        NotifyAcceptanceRequest instance) =>
    <String, dynamic>{
      'mnemonic': instance.mnemonic,
      'offerLink': instance.offerLink,
      'did': instance.did,
      'senderInfo': instance.senderInfo,
    };
