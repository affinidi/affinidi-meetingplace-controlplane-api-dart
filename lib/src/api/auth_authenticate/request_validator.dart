import 'package:lucid_validation/lucid_validation.dart';

class AuthAuthenticateRequestValidator extends LucidValidator {
  AuthAuthenticateRequestValidator() {
    ruleFor((request) => request['challengeResponse'] as String?,
            key: 'challengeResponse')
        .notEmptyOrNull();
  }
}
