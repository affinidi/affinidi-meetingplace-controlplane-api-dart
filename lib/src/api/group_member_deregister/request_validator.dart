import 'package:lucid_validation/lucid_validation.dart';

class GroupMemberDeregisterRequestValidator extends LucidValidator {
  GroupMemberDeregisterRequestValidator() {
    ruleFor(
      (request) => request['groupId'] as String?,
      key: 'groupId',
    ).notEmptyOrNull();

    ruleFor(
      (request) => request['memberDid'] as String?,
      key: 'memberDid',
    ).notEmptyOrNull();

    ruleFor(
      (request) => request['messageToRelay'] as String?,
      key: 'messageToRelay',
    ).notEmptyOrNull();
  }
}
