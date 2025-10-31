// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeregisterOfferRequest _$DeregisterOfferRequestFromJson(
        Map<String, dynamic> json) =>
    DeregisterOfferRequest(
      offerLink: json['offerLink'] as String,
      mnemonic: json['mnemonic'] as String,
    );

Map<String, dynamic> _$DeregisterOfferRequestToJson(
        DeregisterOfferRequest instance) =>
    <String, dynamic>{
      'offerLink': instance.offerLink,
      'mnemonic': instance.mnemonic,
    };
