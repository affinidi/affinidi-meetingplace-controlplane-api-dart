// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateOobRequest _$CreateOobRequestFromJson(Map<String, dynamic> json) =>
    CreateOobRequest(
      mediatorDid: json['mediatorDid'] as String,
      mediatorEndpoint: json['mediatorEndpoint'] as String,
      mediatorWSSEndpoint: json['mediatorWSSEndpoint'] as String,
      didcommMessage: json['didcommMessage'] as String,
    );

Map<String, dynamic> _$CreateOobRequestToJson(CreateOobRequest instance) =>
    <String, dynamic>{
      'mediatorDid': instance.mediatorDid,
      'mediatorEndpoint': instance.mediatorEndpoint,
      'mediatorWSSEndpoint': instance.mediatorWSSEndpoint,
      'didcommMessage': instance.didcommMessage,
    };
