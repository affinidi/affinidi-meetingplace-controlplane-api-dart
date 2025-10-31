// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_error_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AcceptOfferGroupErrorResponse _$AcceptOfferGroupErrorResponseFromJson(
        Map<String, dynamic> json) =>
    AcceptOfferGroupErrorResponse(
      errorCode: json['errorCode'] as String,
      errorMessage: json['errorMessage'] as String,
    );

Map<String, dynamic> _$AcceptOfferGroupErrorResponseToJson(
        AcceptOfferGroupErrorResponse instance) =>
    <String, dynamic>{
      'errorCode': instance.errorCode,
      'errorMessage': instance.errorMessage,
    };
