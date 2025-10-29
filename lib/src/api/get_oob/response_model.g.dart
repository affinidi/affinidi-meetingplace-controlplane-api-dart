// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetOobResponse _$GetOobResponseFromJson(Map<String, dynamic> json) =>
    GetOobResponse(
      oobId: json['oobId'] as String,
      didcommMessage: json['didcommMessage'] as String,
      mediatorDid: json['mediatorDid'] as String,
      mediatorEndpoint: json['mediatorEndpoint'] as String,
      mediatorWSSEndpoint: json['mediatorWSSEndpoint'] as String,
    );

Map<String, dynamic> _$GetOobResponseToJson(GetOobResponse instance) =>
    <String, dynamic>{
      'oobId': instance.oobId,
      'didcommMessage': instance.didcommMessage,
      'mediatorDid': instance.mediatorDid,
      'mediatorEndpoint': instance.mediatorEndpoint,
      'mediatorWSSEndpoint': instance.mediatorWSSEndpoint,
    };
