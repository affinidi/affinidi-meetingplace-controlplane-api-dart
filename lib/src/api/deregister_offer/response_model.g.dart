// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeregisterOfferResponse _$DeregisterOfferResponseFromJson(
  Map<String, dynamic> json,
) => DeregisterOfferResponse(
  status: json['status'] as String,
  message: json['message'] as String,
);

Map<String, dynamic> _$DeregisterOfferResponseToJson(
  DeregisterOfferResponse instance,
) => <String, dynamic>{'status': instance.status, 'message': instance.message};
