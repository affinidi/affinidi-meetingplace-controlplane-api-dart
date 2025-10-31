import 'package:lucid_validation/lucid_validation.dart';

class NotifyOutreachRequestValidator extends LucidValidator {
  NotifyOutreachRequestValidator() {
    ruleFor((request) => request['mnemonic'] as String?, key: 'mnemonic')
        .notEmptyOrNull();

    ruleFor((request) => request['senderInfo'] as String?, key: 'senderInfo')
        .notEmptyOrNull();
  }
}
