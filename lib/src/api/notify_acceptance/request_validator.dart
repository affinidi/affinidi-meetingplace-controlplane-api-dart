import 'package:lucid_validation/lucid_validation.dart';

class NotifyAcceptanceRequestValidator extends LucidValidator {
  NotifyAcceptanceRequestValidator() {
    ruleFor(
      (request) => request['mnemonic'] as String?,
      key: 'mnemonic',
    ).notEmptyOrNull();

    ruleFor(
      (request) => request['offerLink'] as String?,
      key: 'offerLink',
    ).notEmptyOrNull();

    ruleFor(
      (request) => request['did'] as String?,
      key: 'did',
    ).notEmptyOrNull();

    ruleFor(
      (request) => request['senderInfo'] as String?,
      key: 'senderInfo',
    ).notEmptyOrNull();
  }
}
