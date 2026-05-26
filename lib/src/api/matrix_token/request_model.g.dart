// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatrixTokenRequest _$MatrixTokenRequestFromJson(Map<String, dynamic> json) =>
    MatrixTokenRequest(
      challengeResponse: json['challenge_response'] as String,
      homeserver: json['homeserver'] as String,
    );

Map<String, dynamic> _$MatrixTokenRequestToJson(MatrixTokenRequest instance) =>
    <String, dynamic>{
      'challenge_response': instance.challengeResponse,
      'homeserver': instance.homeserver,
    };
