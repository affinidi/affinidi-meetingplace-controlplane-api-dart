// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'acceptance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Acceptance _$AcceptanceFromJson(Map<String, dynamic> json) =>
    Acceptance(
        id: json['id'] as String,
        did: json['did'] as String,
        offerLink: json['offerLink'] as String,
        vcard: json['vcard'] as String,
        status: $enumDecode(_$StatusEnumMap, json['status']),
        platformEndpointArn: json['platformEndpointArn'] as String,
        platformType: $enumDecode(_$PlatformTypeEnumMap, json['platformType']),
        mediatorDid: json['mediatorDid'] as String,
        mediatorEndpoint: json['mediatorEndpoint'] as String,
        mediatorWSSEndpoint: json['mediatorWSSEndpoint'] as String,
        createdBy: json['createdBy'] as String,
      )
      ..ttl = json['ttl'] == null ? null : DateTime.parse(json['ttl'] as String)
      ..modifiedBy = json['modifiedBy'] as String
      ..createdAt = json['createdAt'] as String
      ..modifiedAt = json['modifiedAt'] as String;

Map<String, dynamic> _$AcceptanceToJson(Acceptance instance) =>
    <String, dynamic>{
      'ttl': instance.ttl?.toIso8601String(),
      'id': instance.id,
      'did': instance.did,
      'offerLink': instance.offerLink,
      'vcard': instance.vcard,
      'status': _$StatusEnumMap[instance.status]!,
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

const _$StatusEnumMap = {Status.created: 'CREATED', Status.deleted: 'DELETED'};

const _$PlatformTypeEnumMap = {
  PlatformType.DIDCOMM: 'DIDCOMM',
  PlatformType.PUSH_NOTIFICATION: 'PUSH_NOTIFICATION',
  PlatformType.NONE: 'NONE',
};
