import 'package:lucid_validation/lucid_validation.dart';

class AuthAuthenticateRequestValidator extends LucidValidator {
  AuthAuthenticateRequestValidator() {
    ruleFor(
      (request) => request['challenge_response'] as String?,
      key: 'challenge_response',
    ).notEmptyOrNull();
  }
}
