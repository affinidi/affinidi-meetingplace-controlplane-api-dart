import 'package:lucid_validation/lucid_validation.dart';

class DeregisterNotificationRequestValidator extends LucidValidator {
  DeregisterNotificationRequestValidator() {
    ruleFor((request) => request['notificationToken'] as String?,
            key: 'notificationToken')
        .notEmptyOrNull();
  }
}
