import 'package:lucid_validation/lucid_validation.dart';

import '../../utils/platform_type.dart';

class AcceptOfferGroupRequestValidator extends LucidValidator {
  AcceptOfferGroupRequestValidator() {
    ruleFor(
      (request) => request['did'] as String?,
      key: 'did',
    ).notEmptyOrNull();

    ruleFor(
      (request) => request['mnemonic'] as String?,
      key: 'mnemonic',
    ).notEmptyOrNull();

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
      (request) => request['contactCard'] as String?,
      key: 'contactCard',
    ).must(
      (value) => value != null,
      'contactCard is required',
      'contactCard_required',
    );
  }
}
