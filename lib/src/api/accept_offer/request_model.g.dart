// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AcceptOfferRequest _$AcceptOfferRequestFromJson(Map<String, dynamic> json) =>
    AcceptOfferRequest(
      did: json['did'] as String,
      mnemonic: json['mnemonic'] as String,
      deviceToken: json['deviceToken'] as String,
      platformType: $enumDecode(_$PlatformTypeEnumMap, json['platformType']),
      vcard: json['vcard'] as String,
    );

Map<String, dynamic> _$AcceptOfferRequestToJson(AcceptOfferRequest instance) =>
    <String, dynamic>{
      'did': instance.did,
      'mnemonic': instance.mnemonic,
      'deviceToken': instance.deviceToken,
      'platformType': _$PlatformTypeEnumMap[instance.platformType]!,
      'vcard': instance.vcard,
    };

const _$PlatformTypeEnumMap = {
  PlatformType.DIDCOMM: 'DIDCOMM',
  PlatformType.PUSH_NOTIFICATION: 'PUSH_NOTIFICATION',
  PlatformType.NONE: 'NONE',
};
