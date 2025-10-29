// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bip32.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Bip32 _$Bip32FromJson(Map<String, dynamic> json) => Bip32(
      ttl: json['ttl'] == null ? null : DateTime.parse(json['ttl'] as String),
      accountingIndex: json['accountingIndex'] as String,
    );

Map<String, dynamic> _$Bip32ToJson(Bip32 instance) => <String, dynamic>{
      'ttl': instance.ttl?.toIso8601String(),
      'accountingIndex': instance.accountingIndex,
    };
