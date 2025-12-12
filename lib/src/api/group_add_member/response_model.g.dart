// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupAddMemberResponse _$GroupAddMemberResponseFromJson(
  Map<String, dynamic> json,
) => GroupAddMemberResponse(
  status: json['status'] as String,
  message: json['message'] as String,
);

Map<String, dynamic> _$GroupAddMemberResponseToJson(
  GroupAddMemberResponse instance,
) => <String, dynamic>{'status': instance.status, 'message': instance.message};
