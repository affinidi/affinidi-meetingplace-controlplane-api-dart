// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_error_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupMemberDeregisterErrorResponse _$GroupMemberDeregisterErrorResponseFromJson(
  Map<String, dynamic> json,
) => GroupMemberDeregisterErrorResponse(
  errorCode: json['errorCode'] as String,
  errorMessage: json['errorMessage'] as String,
);

Map<String, dynamic> _$GroupMemberDeregisterErrorResponseToJson(
  GroupMemberDeregisterErrorResponse instance,
) => <String, dynamic>{
  'errorCode': instance.errorCode,
  'errorMessage': instance.errorMessage,
};
