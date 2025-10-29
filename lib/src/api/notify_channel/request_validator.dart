import 'package:lucid_validation/lucid_validation.dart';

class NotifyChannelRequestValidator extends LucidValidator {
  NotifyChannelRequestValidator() {
    ruleFor((request) => request['notificationChannelId'] as String?,
            key: 'notificationChannelId')
        .notEmptyOrNull();

    ruleFor((request) => request['did'] as String?, key: 'did')
        .notEmptyOrNull();

    ruleFor((request) => request['type'] as String?, key: 'type')
        .notEmptyOrNull();
  }
}
