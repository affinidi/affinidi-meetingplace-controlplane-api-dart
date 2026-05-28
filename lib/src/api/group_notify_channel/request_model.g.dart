// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupNotifyChannel _$GroupNotifyChannelFromJson(Map<String, dynamic> json) =>
    GroupNotifyChannel(
      offerLink: json['offerLink'] as String,
      groupDid: json['groupDid'] as String,
      type: json['type'] as String,
    );

Map<String, dynamic> _$GroupNotifyChannelToJson(GroupNotifyChannel instance) =>
    <String, dynamic>{
      'offerLink': instance.offerLink,
      'groupDid': instance.groupDid,
      'type': instance.type,
    };
