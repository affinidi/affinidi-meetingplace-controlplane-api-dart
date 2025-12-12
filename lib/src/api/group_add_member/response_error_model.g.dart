// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_error_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupAddMemberErrorResponse _$GroupAddMemberErrorResponseFromJson(
  Map<String, dynamic> json,
) => GroupAddMemberErrorResponse(
  errorCode: json['errorCode'] as String,
  errorMessage: json['errorMessage'] as String,
);

Map<String, dynamic> _$GroupAddMemberErrorResponseToJson(
  GroupAddMemberErrorResponse instance,
) => <String, dynamic>{
  'errorCode': instance.errorCode,
  'errorMessage': instance.errorMessage,
};
