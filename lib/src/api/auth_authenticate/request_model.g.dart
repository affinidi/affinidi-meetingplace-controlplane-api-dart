// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthAuthenticateRequest _$AuthAuthenticateRequestFromJson(
        Map<String, dynamic> json) =>
    AuthAuthenticateRequest(
      challengeResponse: json['challenge_response'] as String,
    );

Map<String, dynamic> _$AuthAuthenticateRequestToJson(
        AuthAuthenticateRequest instance) =>
    <String, dynamic>{
      'challenge_response': instance.challengeResponse,
    };
