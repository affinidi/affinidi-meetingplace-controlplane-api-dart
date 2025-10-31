// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_group_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeleteGroupInput _$DeleteGroupInputFromJson(Map<String, dynamic> json) =>
    DeleteGroupInput(
      groupId: json['groupId'] as String,
      messageToRelay: json['messageToRelay'] as String,
      controllingDid: json['controllingDid'] as String,
    );

Map<String, dynamic> _$DeleteGroupInputToJson(DeleteGroupInput instance) =>
    <String, dynamic>{
      'groupId': instance.groupId,
      'messageToRelay': instance.messageToRelay,
      'controllingDid': instance.controllingDid,
    };
