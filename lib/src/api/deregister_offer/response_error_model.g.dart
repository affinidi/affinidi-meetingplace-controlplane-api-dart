// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_error_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeregisterOfferErrorResponse _$DeregisterOfferErrorResponseFromJson(
        Map<String, dynamic> json) =>
    DeregisterOfferErrorResponse(
      errorCode: json['errorCode'] as String,
      errorMessage: json['errorMessage'] as String,
    );

Map<String, dynamic> _$DeregisterOfferErrorResponseToJson(
        DeregisterOfferErrorResponse instance) =>
    <String, dynamic>{
      'errorCode': instance.errorCode,
      'errorMessage': instance.errorMessage,
    };
