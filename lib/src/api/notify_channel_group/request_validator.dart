import 'package:lucid_validation/lucid_validation.dart';

class NotifyChannelGroupRequestValidator extends LucidValidator {
  NotifyChannelGroupRequestValidator() {
    ruleFor(
      (request) => request['groupId'] as String?,
      key: 'groupId',
    ).notEmptyOrNull();

    ruleFor(
      (request) => request['type'] as String?,
      key: 'type',
    ).notEmptyOrNull();
  }
}
