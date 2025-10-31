// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthAuthenticateResponse _$AuthAuthenticateResponseFromJson(
        Map<String, dynamic> json) =>
    AuthAuthenticateResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      accessExpiresAt: DateTime.parse(json['access_expires_at'] as String),
      refreshExpiresAt: DateTime.parse(json['refresh_expires_at'] as String),
    );

Map<String, dynamic> _$AuthAuthenticateResponseToJson(
        AuthAuthenticateResponse instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'access_expires_at':
          AuthAuthenticateResponse._dateTimeToJson(instance.accessExpiresAt),
      'refresh_expires_at':
          AuthAuthenticateResponse._dateTimeToJson(instance.refreshExpiresAt),
    };
