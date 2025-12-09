// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_offer_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterOfferInput _$RegisterOfferInputFromJson(Map<String, dynamic> json) =>
    RegisterOfferInput(
      offerName: json['offerName'] as String,
      offerDescription: json['offerDescription'] as String,
      offerType: $enumDecode(_$OfferTypeEnumMap, json['offerType']),
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
      customPhrase: json['customPhrase'] as String?,
      metadata: json['metadata'] as String?,
    );

Map<String, dynamic> _$RegisterOfferInputToJson(RegisterOfferInput instance) =>
    <String, dynamic>{
      'offerName': instance.offerName,
      'offerDescription': instance.offerDescription,
      'offerType': _$OfferTypeEnumMap[instance.offerType]!,
      'didcommMessage': instance.didcommMessage,
      'contactCard': instance.contactCard,
      'deviceToken': instance.deviceToken,
      'platformType': _$PlatformTypeEnumMap[instance.platformType]!,
      'mediatorDid': instance.mediatorDid,
      'mediatorEndpoint': instance.mediatorEndpoint,
      'mediatorWSSEndpoint': instance.mediatorWSSEndpoint,
      'contactAttributes': instance.contactAttributes,
      'validUntil': instance.validUntil,
      'maximumUsage': instance.maximumUsage,
      'customPhrase': instance.customPhrase,
      'metadata': instance.metadata,
    };

const _$OfferTypeEnumMap = {
  OfferType.unspecified: 'UNSPECIFIED',
  OfferType.chat: 'CHAT',
  OfferType.poll: 'POLL',
  OfferType.group: 'GROUP',
  OfferType.outreach: 'OUTREACH',
};

const _$PlatformTypeEnumMap = {
  PlatformType.DIDCOMM: 'DIDCOMM',
  PlatformType.PUSH_NOTIFICATION: 'PUSH_NOTIFICATION',
  PlatformType.NONE: 'NONE',
};
