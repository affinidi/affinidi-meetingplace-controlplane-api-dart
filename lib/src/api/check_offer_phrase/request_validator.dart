import 'package:lucid_validation/lucid_validation.dart';

class CheckOfferPhraseRequestValidator
    extends LucidValidator<Map<String, dynamic>> {
  CheckOfferPhraseRequestValidator() {
    ruleFor((request) => request['offerPhrase'] as String?, key: 'offerPhrase')
        .isNotNull()
        .notEmpty();
  }
}
