// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterOfferRequest _$RegisterOfferRequestFromJson(
  Map<String, dynamic> json,
) => RegisterOfferRequest(
  offerName: json['offerName'] as String,
  offerDescription: json['offerDescription'] as String,
  didcommMessage: json['didcommMessage'] as String,
  contactCard: json['contactCard'] as String,
  deviceToken: json['deviceToken'] as String,
  platformType: $enumDecode(_$PlatformTypeEnumMap, json['platformType']),
  mediatorDid: json['mediatorDid'] as String,
  mediatorEndpoint: json['mediatorEndpoint'] as String,
  mediatorWSSEndpoint: json['mediatorWSSEndpoint'] as String,
  contactAttributes: (json['contactAttributes'] as num).toInt(),
  validUntil: json['validUntil'] as String?,
  maximumUsage: (json['maximumUsage'] as num?)?.toInt(),
  customPhrase: json['customPhrase'],
  score: (json['score'] as num?)?.toInt(),
);

Map<String, dynamic> _$RegisterOfferRequestToJson(
  RegisterOfferRequest instance,
) => <String, dynamic>{
  'offerName': instance.offerName,
  'offerDescription': instance.offerDescription,
  'didcommMessage': instance.didcommMessage,
  'contactCard': instance.contactCard,
  'deviceToken': instance.deviceToken,
  'platformType': _$PlatformTypeEnumMap[instance.platformType]!,
  'mediatorDid': instance.mediatorDid,
  'mediatorEndpoint': instance.mediatorEndpoint,
  'mediatorWSSEndpoint': instance.mediatorWSSEndpoint,
  'contactAttributes': instance.contactAttributes,
  'maximumUsage': instance.maximumUsage,
  'validUntil': instance.validUntil,
  'customPhrase': instance.customPhrase,
  'score': instance.score,
};

const _$PlatformTypeEnumMap = {
  PlatformType.DIDCOMM: 'DIDCOMM',
  PlatformType.PUSH_NOTIFICATION: 'PUSH_NOTIFICATION',
  PlatformType.NONE: 'NONE',
};
