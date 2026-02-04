// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Offer _$OfferFromJson(Map<String, dynamic> json) =>
    Offer(
        ttl: json['ttl'] == null ? null : DateTime.parse(json['ttl'] as String),
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        offerType: $enumDecode(_$OfferTypeEnumMap, json['offerType']),
        didcommMessage: json['didcommMessage'] as String,
        contactCard: json['contactCard'] as String,
        platformEndpointArn: json['platformEndpointArn'] as String,
        platformType: $enumDecode(_$PlatformTypeEnumMap, json['platformType']),
        mediatorDid: json['mediatorDid'] as String,
        mediatorEndpoint: json['mediatorEndpoint'] as String,
        mediatorWSSEndpoint: json['mediatorWSSEndpoint'] as String,
        mnemonic: json['mnemonic'] as String,
        offerLink: json['offerLink'] as String,
        contactAttributes: (json['contactAttributes'] as num).toInt(),
        createdBy: json['createdBy'] as String,
        maximumClaims: (json['maximumClaims'] as num?)?.toInt(),
        maximumQueries: (json['maximumQueries'] as num?)?.toInt(),
        validUntil: json['validUntil'] as String?,
        customPhrase: json['customPhrase'] as String?,
        metadata: json['metadata'] as String?,
        groupId: json['groupId'] as String?,
        groupDid: json['groupDid'] as String?,
        vrcCount: (json['vrcCount'] as num?)?.toInt(),
      )
      ..queryCount = (json['queryCount'] as num).toInt()
      ..claimCount = (json['claimCount'] as num).toInt()
      ..modifiedBy = json['modifiedBy'] as String
      ..createdAt = json['createdAt'] as String
      ..modifiedAt = json['modifiedAt'] as String;

Map<String, dynamic> _$OfferToJson(Offer instance) => <String, dynamic>{
  'ttl': instance.ttl?.toIso8601String(),
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'didcommMessage': instance.didcommMessage,
  'contactCard': instance.contactCard,
  'mnemonic': instance.mnemonic,
  'offerLink': instance.offerLink,
  'offerType': _$OfferTypeEnumMap[instance.offerType]!,
  'contactAttributes': instance.contactAttributes,
  'validUntil': instance.validUntil,
  'customPhrase': instance.customPhrase,
  'metadata': instance.metadata,
  'vrcCount': instance.vrcCount,
  'groupId': instance.groupId,
  'groupDid': instance.groupDid,
  'queryCount': instance.queryCount,
  'claimCount': instance.claimCount,
  'maximumClaims': instance.maximumClaims,
  'maximumQueries': instance.maximumQueries,
  'platformEndpointArn': instance.platformEndpointArn,
  'platformType': _$PlatformTypeEnumMap[instance.platformType]!,
  'mediatorDid': instance.mediatorDid,
  'mediatorEndpoint': instance.mediatorEndpoint,
  'mediatorWSSEndpoint': instance.mediatorWSSEndpoint,
  'createdBy': instance.createdBy,
  'modifiedBy': instance.modifiedBy,
  'createdAt': instance.createdAt,
  'modifiedAt': instance.modifiedAt,
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
