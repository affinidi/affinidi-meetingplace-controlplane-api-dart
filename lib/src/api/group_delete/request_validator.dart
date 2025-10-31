import 'package:lucid_validation/lucid_validation.dart';

class GroupDeleteRequestValidator extends LucidValidator {
  GroupDeleteRequestValidator() {
    ruleFor((request) => request['groupId'] as String?, key: 'groupId')
        .notEmptyOrNull();

    ruleFor((request) => request['messageToRelay'] as String?,
            key: 'messageToRelay')
        .notEmptyOrNull();
  }
}
