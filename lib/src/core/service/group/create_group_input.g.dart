// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_group_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateGroupInput _$CreateGroupInputFromJson(Map<String, dynamic> json) =>
    CreateGroupInput(
      offerLink: json['offerLink'] as String,
      groupName: json['groupName'] as String,
      mediatorDid: json['mediatorDid'] as String,
      controllingDid: json['controllingDid'] as String,
      createdBy: json['createdBy'] as String,
      modifiedBy: json['modifiedBy'] as String,
    );

Map<String, dynamic> _$CreateGroupInputToJson(CreateGroupInput instance) =>
    <String, dynamic>{
      'offerLink': instance.offerLink,
      'groupName': instance.groupName,
      'mediatorDid': instance.mediatorDid,
      'controllingDid': instance.controllingDid,
      'createdBy': instance.createdBy,
      'modifiedBy': instance.modifiedBy,
    };
