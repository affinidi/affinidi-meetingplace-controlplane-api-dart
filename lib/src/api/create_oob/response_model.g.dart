// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateOobResponse _$CreateOobResponseFromJson(Map<String, dynamic> json) =>
    CreateOobResponse(
      oobId: json['oobId'] as String,
      oobUrl: json['oobUrl'] as String,
    );

Map<String, dynamic> _$CreateOobResponseToJson(CreateOobResponse instance) =>
    <String, dynamic>{'oobId': instance.oobId, 'oobUrl': instance.oobUrl};
