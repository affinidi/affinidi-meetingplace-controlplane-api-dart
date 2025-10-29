// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupMemberDeregisterRequest _$GroupMemberDeregisterRequestFromJson(
        Map<String, dynamic> json) =>
    GroupMemberDeregisterRequest(
      groupId: json['groupId'] as String,
      memberDid: json['memberDid'] as String,
      messageToRelay: json['messageToRelay'] as String,
    );

Map<String, dynamic> _$GroupMemberDeregisterRequestToJson(
        GroupMemberDeregisterRequest instance) =>
    <String, dynamic>{
      'groupId': instance.groupId,
      'memberDid': instance.memberDid,
      'messageToRelay': instance.messageToRelay,
    };
