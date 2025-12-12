// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupDeleteResponse _$GroupDeleteResponseFromJson(Map<String, dynamic> json) =>
    GroupDeleteResponse(
      status: json['status'] as String,
      message: json['message'] as String,
    );

Map<String, dynamic> _$GroupDeleteResponseToJson(
  GroupDeleteResponse instance,
) => <String, dynamic>{'status': instance.status, 'message': instance.message};
