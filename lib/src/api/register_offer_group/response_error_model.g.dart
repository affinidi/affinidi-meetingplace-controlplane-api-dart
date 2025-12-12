// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_error_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterOfferGroupErrorResponse _$RegisterOfferGroupErrorResponseFromJson(
  Map<String, dynamic> json,
) => RegisterOfferGroupErrorResponse(
  errorCode: json['errorCode'] as String,
  errorMessage: json['errorMessage'] as String,
);

Map<String, dynamic> _$RegisterOfferGroupErrorResponseToJson(
  RegisterOfferGroupErrorResponse instance,
) => <String, dynamic>{
  'errorCode': instance.errorCode,
  'errorMessage': instance.errorMessage,
};
