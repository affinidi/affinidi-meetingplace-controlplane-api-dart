import 'package:lucid_validation/lucid_validation.dart';

import '../../utils/platform_type.dart';

class RegisterDeviceRequestValidator extends LucidValidator {
  RegisterDeviceRequestValidator() {
    ruleFor((request) => request['deviceToken'] as String?, key: 'deviceToken')
        .notEmptyOrNull()
        .maxLength(2048);

    ruleFor((request) => request['platformType'] as String?,
            key: 'platformType')
        .must(
            (value) => PlatformType.values.any((e) => e.name == value),
            'Platform type must be one of ${PlatformType.values.join(',')}',
            'invalidPlatformType');
  }
}
