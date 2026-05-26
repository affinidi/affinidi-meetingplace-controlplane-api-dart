import 'package:lucid_validation/lucid_validation.dart';

class GroupNotifyChannelValidator extends LucidValidator {
  GroupNotifyChannelValidator() {
    ruleFor(
      (request) => request['offerLink'] as String?,
      key: 'offerLink',
    ).notEmptyOrNull();

    ruleFor(
      (request) => request['groupDid'] as String?,
      key: 'groupDid',
    ).notEmptyOrNull();

    ruleFor(
      (request) => request['type'] as String?,
      key: 'type',
    ).notEmptyOrNull();
  }
}
