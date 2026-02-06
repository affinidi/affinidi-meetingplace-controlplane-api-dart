import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'response_error_model.g.dart';

enum UpdateOffersScoreErrorCodes {
  permissionDenied('permission_denied'),
  notFound('not_found'),
  validationFailed('validation_failed');

  const UpdateOffersScoreErrorCodes(this.value);

  final String value;
}

@JsonSerializable()
class UpdateOffersScoreErrorResponse {
  UpdateOffersScoreErrorResponse({
    required this.errorCode,
    required this.errorMessage,
  });

  factory UpdateOffersScoreErrorResponse.permissionDenied() {
    return UpdateOffersScoreErrorResponse(
      errorCode: UpdateOffersScoreErrorCodes.permissionDenied.value,
      errorMessage: 'Update offers score exception: permission denied',
    );
  }

  factory UpdateOffersScoreErrorResponse.notFound() {
    return UpdateOffersScoreErrorResponse(
      errorCode: UpdateOffersScoreErrorCodes.notFound.value,
      errorMessage: 'Update offers score exception: offer not found',
    );
  }

  factory UpdateOffersScoreErrorResponse.validationFailed(String message) {
    return UpdateOffersScoreErrorResponse(
      errorCode: UpdateOffersScoreErrorCodes.validationFailed.value,
      errorMessage: 'Update offers score exception: $message',
    );
  }

  final String errorCode;
  final String errorMessage;

  @override
  String toString() => jsonEncode(toJson());

  Map<String, dynamic> toJson() => _$UpdateOffersScoreErrorResponseToJson(this);
}
