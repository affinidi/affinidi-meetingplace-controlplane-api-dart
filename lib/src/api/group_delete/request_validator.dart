import 'package:lucid_validation/lucid_validation.dart';

class GroupDeleteRequestValidator extends LucidValidator {
  GroupDeleteRequestValidator() {
    ruleFor(
      (request) => request['groupId'] as String?,
      key: 'groupId',
    ).notEmptyOrNull();
  }
}
