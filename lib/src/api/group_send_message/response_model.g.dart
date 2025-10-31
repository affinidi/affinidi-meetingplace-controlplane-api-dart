// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupSendMessageResponse _$GroupSendMessageResponseFromJson(
        Map<String, dynamic> json) =>
    GroupSendMessageResponse(
      status: json['status'] as String,
      message: json['message'] as String,
    );

Map<String, dynamic> _$GroupSendMessageResponseToJson(
        GroupSendMessageResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message': instance.message,
    };
