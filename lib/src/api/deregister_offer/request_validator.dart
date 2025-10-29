import 'package:lucid_validation/lucid_validation.dart';

class DeregisterOfferRequestValidator extends LucidValidator {
  DeregisterOfferRequestValidator() {
    ruleFor((request) => request['offerLink'] as String?, key: 'offerLink')
        .notEmptyOrNull();

    ruleFor((request) => request['mnemonic'] as String?, key: 'mnemonic')
        .notEmptyOrNull();
  }
}
