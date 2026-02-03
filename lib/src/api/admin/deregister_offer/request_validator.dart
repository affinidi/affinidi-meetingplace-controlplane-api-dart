import 'package:lucid_validation/lucid_validation.dart';

class AdminDeregisterOfferRequestValidator extends LucidValidator {
  AdminDeregisterOfferRequestValidator() {
    ruleFor(
      (request) => request['mnemonic'] as String?,
      key: 'mnemonic',
    ).notEmptyOrNull();
  }
}
