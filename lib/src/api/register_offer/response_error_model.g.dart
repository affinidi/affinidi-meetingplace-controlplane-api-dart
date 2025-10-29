// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_error_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterOfferErrorResponse _$RegisterOfferErrorResponseFromJson(
        Map<String, dynamic> json) =>
    RegisterOfferErrorResponse(
      errorCode: json['errorCode'] as String,
      errorMessage: json['errorMessage'] as String,
    );

Map<String, dynamic> _$RegisterOfferErrorResponseToJson(
        RegisterOfferErrorResponse instance) =>
    <String, dynamic>{
      'errorCode': instance.errorCode,
      'errorMessage': instance.errorMessage,
    };
