import 'package:lucid_validation/lucid_validation.dart';

class QueryOfferRequestValidator extends LucidValidator {
  QueryOfferRequestValidator() {
    ruleFor(
      (request) => request['mnemonic'] as String?,
      key: 'mnemonic',
    ).notEmptyOrNull();
  }
}
