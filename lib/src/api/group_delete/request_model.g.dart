// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupDeleteRequest _$GroupDeleteRequestFromJson(Map<String, dynamic> json) =>
    GroupDeleteRequest(
      groupId: json['groupId'] as String,
      messageToRelay: json['messageToRelay'] as String,
    );

Map<String, dynamic> _$GroupDeleteRequestToJson(GroupDeleteRequest instance) =>
    <String, dynamic>{
      'groupId': instance.groupId,
      'messageToRelay': instance.messageToRelay,
    };
