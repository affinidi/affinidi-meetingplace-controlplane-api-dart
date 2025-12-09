// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AcceptOfferResponse _$AcceptOfferResponseFromJson(Map<String, dynamic> json) =>
    AcceptOfferResponse(
      didcommMessage: json['didcommMessage'] as String,
      offerLink: json['offerLink'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      contactCard: json['contactCard'] as String,
      validUntil: json['validUntil'] as String?,
      mediatorDid: json['mediatorDid'] as String,
      mediatorEndpoint: json['mediatorEndpoint'] as String,
      mediatorWSSEndpoint: json['mediatorWSSEndpoint'] as String,
    );

Map<String, dynamic> _$AcceptOfferResponseToJson(
  AcceptOfferResponse instance,
) => <String, dynamic>{
  'didcommMessage': instance.didcommMessage,
  'offerLink': instance.offerLink,
  'name': instance.name,
  'description': instance.description,
  'contactCard': instance.contactCard,
  'validUntil': instance.validUntil,
  'mediatorDid': instance.mediatorDid,
  'mediatorEndpoint': instance.mediatorEndpoint,
  'mediatorWSSEndpoint': instance.mediatorWSSEndpoint,
};
