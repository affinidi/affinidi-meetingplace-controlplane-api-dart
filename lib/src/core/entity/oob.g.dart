// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'oob.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Oob _$OobFromJson(Map<String, dynamic> json) => Oob(
      ttl: json['ttl'] == null ? null : DateTime.parse(json['ttl'] as String),
      oobId: json['oobId'] as String,
      didcommMessage: json['didcommMessage'] as String,
      mediatorDid: json['mediatorDid'] as String,
      mediatorEndpoint: json['mediatorEndpoint'] as String,
      mediatorWSSEndpoint: json['mediatorWSSEndpoint'] as String,
    );

Map<String, dynamic> _$OobToJson(Oob instance) => <String, dynamic>{
      'ttl': instance.ttl?.toIso8601String(),
      'oobId': instance.oobId,
      'didcommMessage': instance.didcommMessage,
      'mediatorDid': instance.mediatorDid,
      'mediatorEndpoint': instance.mediatorEndpoint,
      'mediatorWSSEndpoint': instance.mediatorWSSEndpoint,
    };
