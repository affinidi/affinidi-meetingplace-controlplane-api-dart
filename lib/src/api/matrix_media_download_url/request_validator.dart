import 'package:lucid_validation/lucid_validation.dart';

import '../request_validation.dart';

class MatrixMediaDownloadUrlRequestValidator extends LucidValidator {
  MatrixMediaDownloadUrlRequestValidator() {
    ruleFor(
      (request) => request['challenge_response'] as String?,
      key: 'challenge_response',
    ).notEmptyOrNull();

    ruleFor(
      (request) => request['homeserver'] as String?,
      key: 'homeserver',
    ).notEmptyOrNull().must(
      (v) => v != null && RequestValidation.isValidHomeserverUri(v),
      'Homeserver must be a valid URI.',
      'invalidUri',
    );

    ruleFor(
      (request) => request['room_id'] as String?,
      key: 'room_id',
    ).notEmptyOrNull();

    ruleFor(
      (request) => request['media_uri'] as String?,
      key: 'media_uri',
    ).notEmptyOrNull().must(
      (v) => v != null && RequestValidation.isValidUri(v),
      'Media URI must be a valid URI.',
      'invalidUri',
    );
  }
}
