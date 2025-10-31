// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotifyOutreachResponse _$NotifyOutreachResponseFromJson(
        Map<String, dynamic> json) =>
    NotifyOutreachResponse(
      status: json['status'] as String,
      message: json['message'] as String,
    );

Map<String, dynamic> _$NotifyOutreachResponseToJson(
        NotifyOutreachResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message': instance.message,
    };
