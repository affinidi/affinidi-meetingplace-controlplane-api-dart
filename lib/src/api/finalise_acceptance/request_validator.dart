import 'package:lucid_validation/lucid_validation.dart';

import '../../utils/platform_type.dart';

class FinaliseAcceptanceRequestValidator extends LucidValidator {
  FinaliseAcceptanceRequestValidator() {
    ruleFor((request) => request['did'] as String?, key: 'did')
        .notEmptyOrNull();

    ruleFor((request) => request['theirDid'] as String?, key: 'theirDid')
        .notEmptyOrNull();

    ruleFor((request) => request['mnemonic'] as String?, key: 'mnemonic')
        .notEmptyOrNull();

    ruleFor((request) => request['offerLink'] as String?, key: 'offerLink')
        .notEmptyOrNull();

    ruleFor((request) => request['deviceToken'] as String?, key: 'deviceToken')
        .notEmptyOrNull()
        .must(
            (value) => value == null || value.isNotEmpty,
            'deviceToken must not be empty if provided',
            'invalid_device_token');

    ruleFor((request) => request['platformType'] as String?,
            key: 'platformType')
        .notEmptyOrNull()
        .must(
            (value) =>
                value == null ||
                PlatformType.values.any((e) => e.name == value),
            'Platform type must be one of ${PlatformType.values.join(',')}',
            'invalidPlatformType');
  }
}
