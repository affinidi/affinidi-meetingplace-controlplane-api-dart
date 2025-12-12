import 'package:lucid_validation/lucid_validation.dart';

import '../../utils/platform_type.dart';

class DeletePendingNotificationsRequestValidator extends LucidValidator {
  DeletePendingNotificationsRequestValidator() {
    ruleFor(
      (request) => request['deviceToken'] as String?,
      key: 'deviceToken',
    ).notEmptyOrNull().maxLength(2048);

    ruleFor(
      (request) => request['platformType'] as String?,
      key: 'platformType',
    ).notEmptyOrNull().must(
      (value) => PlatformType.values.any((e) => e.name == value),
      'Platform type must be one of ${PlatformType.values.join(',')}',
      'invalidPlatformType',
    );

    ruleFor(
      (request) => request['notificationIds'] as List<dynamic>,
      key: 'notificationIds',
    ).must(
      (value) => value.isNotEmpty,
      'notificationIds must not be empty',
      'invalidNotificationIds',
    );
  }
}
