import 'package:lucid_validation/lucid_validation.dart';

class GroupNotifyChannelValidator extends LucidValidator {
  GroupNotifyChannelValidator() {
    ruleFor(
      (request) => request['offerLink'] as String?,
      key: 'offerLink',
    ).isNotNull().notEmpty();

    ruleFor(
      (request) => request['groupDid'] as String?,
      key: 'groupDid',
    ).isNotNull().notEmpty();

    ruleFor(
      (request) => request['type'] as String?,
      key: 'type',
    ).isNotNull().notEmpty();
  }
}
