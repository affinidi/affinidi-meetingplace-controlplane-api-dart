// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kms_key.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KmsKey _$KmsKeyFromJson(Map<String, dynamic> json) => KmsKey(
      ttl: json['ttl'] == null ? null : DateTime.parse(json['ttl'] as String),
      keyId: json['keyId'] as String,
      publicKey: json['publicKey'] as String,
    );

Map<String, dynamic> _$KmsKeyToJson(KmsKey instance) => <String, dynamic>{
      'ttl': instance.ttl?.toIso8601String(),
      'keyId': instance.keyId,
      'publicKey': instance.publicKey,
    };
