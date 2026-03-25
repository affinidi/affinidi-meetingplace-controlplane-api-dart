import 'package:lucid_validation/lucid_validation.dart';

class MatrixRegistrationCredentialRequestValidator extends LucidValidator {
  MatrixRegistrationCredentialRequestValidator() {
    ruleFor(
      (request) => request['homeserver'] as String?,
      key: 'homeserver',
    ).notEmptyOrNull();
  }
}
