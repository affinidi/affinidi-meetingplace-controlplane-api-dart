// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupNotifyChannel _$GroupNotifyChannelFromJson(Map<String, dynamic> json) =>
    GroupNotifyChannel(
      groupId: json['groupId'] as String,
      type: json['type'] as String,
      memberDid: json['memberDid'] as String?,
    );

Map<String, dynamic> _$GroupNotifyChannelToJson(GroupNotifyChannel instance) =>
    <String, dynamic>{
      'groupId': instance.groupId,
      'type': instance.type,
      'memberDid': instance.memberDid,
    };
