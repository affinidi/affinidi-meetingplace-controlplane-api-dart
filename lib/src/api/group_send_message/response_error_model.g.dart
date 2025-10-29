// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_error_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupSendMemberErrorResponse _$GroupSendMemberErrorResponseFromJson(
        Map<String, dynamic> json) =>
    GroupSendMemberErrorResponse(
      errorCode: json['errorCode'] as String,
      errorMessage: json['errorMessage'] as String,
    );

Map<String, dynamic> _$GroupSendMemberErrorResponseToJson(
        GroupSendMemberErrorResponse instance) =>
    <String, dynamic>{
      'errorCode': instance.errorCode,
      'errorMessage': instance.errorMessage,
    };
