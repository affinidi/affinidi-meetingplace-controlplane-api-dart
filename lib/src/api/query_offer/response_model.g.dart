// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QueryOfferResponse _$QueryOfferResponseFromJson(Map<String, dynamic> json) =>
    QueryOfferResponse(
      offerLink: json['offerLink'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      vcard: json['vcard'] as String,
      validUntil: json['validUntil'] as String?,
      maximumUsage: (json['maximumUsage'] as num?)?.toInt(),
      mediatorDid: json['mediatorDid'] as String,
      mediatorEndpoint: json['mediatorEndpoint'] as String,
      mediatorWSSEndpoint: json['mediatorWSSEndpoint'] as String,
      didcommMessage: json['didcommMessage'] as String,
      status: json['status'] as String,
      contactAttributes: (json['contactAttributes'] as num).toInt(),
      groupId: json['groupId'] as String?,
      groupDid: json['groupDid'] as String?,
    );

Map<String, dynamic> _$QueryOfferResponseToJson(QueryOfferResponse instance) =>
    <String, dynamic>{
      'offerLink': instance.offerLink,
      'name': instance.name,
      'description': instance.description,
      'vcard': instance.vcard,
      'mediatorDid': instance.mediatorDid,
      'mediatorEndpoint': instance.mediatorEndpoint,
      'mediatorWSSEndpoint': instance.mediatorWSSEndpoint,
      'didcommMessage': instance.didcommMessage,
      'status': instance.status,
      'contactAttributes': instance.contactAttributes,
      'validUntil': instance.validUntil,
      'maximumUsage': instance.maximumUsage,
      'groupId': instance.groupId,
      'groupDid': instance.groupDid,
    };
