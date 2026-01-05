// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_error_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminDeregisterOfferErrorResponse _$AdminDeregisterOfferErrorResponseFromJson(
  Map<String, dynamic> json,
) => AdminDeregisterOfferErrorResponse(
  errorCode: json['errorCode'] as String,
  errorMessage: json['errorMessage'] as String,
);

Map<String, dynamic> _$AdminDeregisterOfferErrorResponseToJson(
  AdminDeregisterOfferErrorResponse instance,
) => <String, dynamic>{
  'errorCode': instance.errorCode,
  'errorMessage': instance.errorMessage,
};
