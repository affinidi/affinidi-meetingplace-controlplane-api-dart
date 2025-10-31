import 'package:lucid_validation/lucid_validation.dart';

class AuthChallengeRequestValidator extends LucidValidator {
  AuthChallengeRequestValidator() {
    ruleFor((request) => request['did'] as String?, key: 'did')
        .notEmptyOrNull();
  }
}
