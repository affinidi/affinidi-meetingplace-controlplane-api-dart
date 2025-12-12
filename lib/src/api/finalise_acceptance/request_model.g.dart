// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FinaliseAcceptanceRequest _$FinaliseAcceptanceRequestFromJson(
  Map<String, dynamic> json,
) => FinaliseAcceptanceRequest(
  did: json['did'] as String,
  theirDid: json['theirDid'] as String,
  mnemonic: json['mnemonic'] as String,
  offerLink: json['offerLink'] as String,
  deviceToken: json['deviceToken'] as String?,
  platformType: $enumDecodeNullable(
    _$PlatformTypeEnumMap,
    json['platformType'],
  ),
);

Map<String, dynamic> _$FinaliseAcceptanceRequestToJson(
  FinaliseAcceptanceRequest instance,
) => <String, dynamic>{
  'did': instance.did,
  'theirDid': instance.theirDid,
  'mnemonic': instance.mnemonic,
  'offerLink': instance.offerLink,
  'deviceToken': instance.deviceToken,
  'platformType': _$PlatformTypeEnumMap[instance.platformType],
};

const _$PlatformTypeEnumMap = {
  PlatformType.DIDCOMM: 'DIDCOMM',
  PlatformType.PUSH_NOTIFICATION: 'PUSH_NOTIFICATION',
  PlatformType.NONE: 'NONE',
};
