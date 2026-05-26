import 'package:lucid_validation/lucid_validation.dart';

class MatrixChallengeRequestValidator extends LucidValidator {
  MatrixChallengeRequestValidator() {
    ruleFor(
      (request) => request['did'] as String?,
      key: 'did',
    ).notEmptyOrNull();
  }
}
