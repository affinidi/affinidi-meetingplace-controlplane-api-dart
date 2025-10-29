// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupSendMessage _$GroupSendMessageFromJson(Map<String, dynamic> json) =>
    GroupSendMessage(
      offerLink: json['offerLink'] as String,
      groupDid: json['groupDid'] as String,
      payload: json['payload'] as String,
      ephemeral: json['ephemeral'] as bool?,
      expiresTime: json['expiresTime'] as String?,
      notify: json['notify'] as bool? ?? false,
      incSeqNo: json['incSeqNo'] as bool? ?? false,
    );

Map<String, dynamic> _$GroupSendMessageToJson(GroupSendMessage instance) =>
    <String, dynamic>{
      'offerLink': instance.offerLink,
      'groupDid': instance.groupDid,
      'payload': instance.payload,
      'ephemeral': instance.ephemeral,
      'expiresTime': instance.expiresTime,
      'notify': instance.notify,
      'incSeqNo': instance.incSeqNo,
    };
