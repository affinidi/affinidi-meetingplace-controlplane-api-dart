// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupNotifyChannelResponse _$GroupNotifyChannelResponseFromJson(
  Map<String, dynamic> json,
) => GroupNotifyChannelResponse(
  status: json['status'] as String,
  message: json['message'] as String,
);

Map<String, dynamic> _$GroupNotifyChannelResponseToJson(
  GroupNotifyChannelResponse instance,
) => <String, dynamic>{'status': instance.status, 'message': instance.message};
