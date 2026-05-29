// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatrixMediaDownloadUrlRequest _$MatrixMediaDownloadUrlRequestFromJson(
  Map<String, dynamic> json,
) => MatrixMediaDownloadUrlRequest(
  challengeResponse: json['challenge_response'] as String,
  homeserver: json['homeserver'] as String,
  roomId: json['room_id'] as String,
  mediaUri: json['media_uri'] as String,
);

Map<String, dynamic> _$MatrixMediaDownloadUrlRequestToJson(
  MatrixMediaDownloadUrlRequest instance,
) => <String, dynamic>{
  'challenge_response': instance.challengeResponse,
  'homeserver': instance.homeserver,
  'room_id': instance.roomId,
  'media_uri': instance.mediaUri,
};
