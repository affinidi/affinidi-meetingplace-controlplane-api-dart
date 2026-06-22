import 'package:lucid_validation/lucid_validation.dart';

import '../request_validation.dart';

class MatrixTokenRequestValidator extends LucidValidator {
  MatrixTokenRequestValidator() {
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
  }
}
