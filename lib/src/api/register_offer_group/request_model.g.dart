// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterOfferGroupRequest _$RegisterOfferGroupRequestFromJson(
  Map<String, dynamic> json,
) => RegisterOfferGroupRequest(
  offerName: json['offerName'] as String,
  offerDescription: json['offerDescription'] as String,
  didcommMessage: json['didcommMessage'] as String,
  contactCard: json['contactCard'] as String,
  deviceToken: json['deviceToken'] as String,
  platformType: $enumDecode(_$PlatformTypeEnumMap, json['platformType']),
  mediatorDid: json['mediatorDid'] as String,
  mediatorEndpoint: json['mediatorEndpoint'] as String,
  mediatorWSSEndpoint: json['mediatorWSSEndpoint'] as String,
  adminReencryptionKey: json['adminReencryptionKey'] as String,
  adminDid: json['adminDid'] as String,
  adminPublicKey: json['adminPublicKey'] as String,
  memberContactCard: json['memberContactCard'] as String,
  validUntil: json['validUntil'] as String?,
  maximumUsage: (json['maximumUsage'] as num?)?.toInt(),
  customPhrase: json['customPhrase'] as String?,
  metadata: json['metadata'] as String?,
)..isSearchable = json['isSearchable'] as bool?;

Map<String, dynamic> _$RegisterOfferGroupRequestToJson(
  RegisterOfferGroupRequest instance,
) => <String, dynamic>{
  'offerName': instance.offerName,
  'offerDescription': instance.offerDescription,
  'didcommMessage': instance.didcommMessage,
  'contactCard': instance.contactCard,
  'validUntil': instance.validUntil,
  'maximumUsage': instance.maximumUsage,
  'deviceToken': instance.deviceToken,
  'platformType': _$PlatformTypeEnumMap[instance.platformType]!,
  'mediatorDid': instance.mediatorDid,
  'mediatorEndpoint': instance.mediatorEndpoint,
  'mediatorWSSEndpoint': instance.mediatorWSSEndpoint,
  'adminReencryptionKey': instance.adminReencryptionKey,
  'adminDid': instance.adminDid,
  'adminPublicKey': instance.adminPublicKey,
  'memberContactCard': instance.memberContactCard,
  'customPhrase': instance.customPhrase,
  'isSearchable': instance.isSearchable,
  'metadata': instance.metadata,
};

const _$PlatformTypeEnumMap = {
  PlatformType.DIDCOMM: 'DIDCOMM',
  PlatformType.PUSH_NOTIFICATION: 'PUSH_NOTIFICATION',
  PlatformType.NONE: 'NONE',
};
