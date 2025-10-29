// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'key_reference.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KeyReference _$KeyReferenceFromJson(Map<String, dynamic> json) => KeyReference(
      keyId: json['keyId'] as String,
      entityId: json['entityId'] as String,
    )..ttl = json['ttl'] == null ? null : DateTime.parse(json['ttl'] as String);

Map<String, dynamic> _$KeyReferenceToJson(KeyReference instance) =>
    <String, dynamic>{
      'ttl': instance.ttl?.toIso8601String(),
      'keyId': instance.keyId,
      'entityId': instance.entityId,
    };
