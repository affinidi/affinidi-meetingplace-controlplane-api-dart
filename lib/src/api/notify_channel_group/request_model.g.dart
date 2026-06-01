// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotifyChannelGroupRequest _$NotifyChannelGroupRequestFromJson(
  Map<String, dynamic> json,
) => NotifyChannelGroupRequest(
  groupId: json['groupId'] as String,
  type: json['type'] as String,
);

Map<String, dynamic> _$NotifyChannelGroupRequestToJson(
  NotifyChannelGroupRequest instance,
) => <String, dynamic>{'groupId': instance.groupId, 'type': instance.type};
