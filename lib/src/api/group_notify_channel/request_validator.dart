import 'package:lucid_validation/lucid_validation.dart';

class GroupNotifyChannelValidator extends LucidValidator {
  GroupNotifyChannelValidator() {
    ruleFor(
      (request) => request['groupId'] as String?,
      key: 'groupId',
    ).isNotNull().notEmpty();

    ruleFor(
      (request) => request['type'] as String?,
      key: 'type',
    ).isNotNull().notEmpty();
  }
}
