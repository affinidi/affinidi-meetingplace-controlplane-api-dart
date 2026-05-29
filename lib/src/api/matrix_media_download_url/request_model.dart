import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../request_validation_exception.dart';
import 'request_validator.dart';

part 'request_model.g.dart';

@JsonSerializable()
class MatrixMediaDownloadUrlRequest {
  MatrixMediaDownloadUrlRequest({
    required this.challengeResponse,
    required this.homeserver,
    required this.roomId,
    required this.mediaUri,
  });

  factory MatrixMediaDownloadUrlRequest.fromRequestParams(
    String requestParams,
  ) {
    final params = jsonDecode(requestParams);

    final validationResult = MatrixMediaDownloadUrlRequestValidator().validate(
      params,
    );

    if (!validationResult.isValid) {
      throw RequestValidationException.fromValidationResult(validationResult);
    }

    return _$MatrixMediaDownloadUrlRequestFromJson(params);
  }

  @JsonKey(name: 'challenge_response')
  final String challengeResponse;

  final String homeserver;

  @JsonKey(name: 'room_id')
  final String roomId;

  @JsonKey(name: 'media_uri')
  final String mediaUri;
}
