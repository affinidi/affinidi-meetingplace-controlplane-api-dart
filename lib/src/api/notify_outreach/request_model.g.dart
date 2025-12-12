// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotifyOutreachRequest _$NotifyOutreachRequestFromJson(
  Map<String, dynamic> json,
) => NotifyOutreachRequest(
  mnemonic: json['mnemonic'] as String,
  senderInfo: json['senderInfo'] as String,
);

Map<String, dynamic> _$NotifyOutreachRequestToJson(
  NotifyOutreachRequest instance,
) => <String, dynamic>{
  'mnemonic': instance.mnemonic,
  'senderInfo': instance.senderInfo,
};
