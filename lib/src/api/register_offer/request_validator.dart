import 'package:lucid_validation/lucid_validation.dart';

import '../../utils/platform_type.dart';
import '../request_validation.dart';

class RegisterOfferRequestValidator extends LucidValidator {
  RegisterOfferRequestValidator() {
    ruleFor(
      (request) => request['offerName'] as String?,
      key: 'offerName',
    ).notEmptyOrNull().minLength(1).maxLength(500);

    ruleFor(
      (request) => request['offerDescription'] as String?,
      key: 'offerDescription',
    ).notEmptyOrNull().minLength(1).maxLength(2000);

    ruleFor(
      (request) => request['didcommMessage'] as String?,
      key: 'didcommMessage',
    ).notEmptyOrNull();

    ruleFor(
      (request) => request['contactCard'] as String?,
      key: 'contactCard',
    ).notEmptyOrNull();

    ruleFor(
      (request) => request['deviceToken'] as String?,
      key: 'deviceToken',
    ).notEmptyOrNull().maxLength(2048);

    ruleFor(
      (request) => request['platformType'] as String?,
      key: 'platformType',
    ).must(
      (value) => PlatformType.values.any((e) => e.name == value),
      'Platform type must be one of ${PlatformType.values.join(',')}',
      'invalidPlatformType',
    );

    ruleFor(
      (request) => request['mediatorDid'] as String?,
      key: 'mediatorDid',
    ).notEmptyOrNull();

    ruleFor(
      (request) => request['mediatorEndpoint'] as String?,
      key: 'mediatorEndpoint',
    ).notEmptyOrNull().must(
      (v) => RequestValidation.isValidUri(v!),
      'Mediator endpoint must be valid uri.',
      'invalidUri',
    );

    ruleFor(
      (request) => request['mediatorWSSEndpoint'] as String?,
      key: 'mediatorWSSEndpoint',
    ).notEmptyOrNull().must(
      (v) => RequestValidation.isValidUri(v!),
      'Mediator web socket endpoint must be valid uri.',
      'invalidUri',
    );

    ruleFor(
      (request) => request['contactAttributes'] as int?,
      key: 'contactAttributes',
    ).min(0);

    ruleFor((request) => request['maximumUsage'], key: 'maximumUsage').must(
      (value) => value == null || value >= 1,
      'maximumUsage must be at least 1',
      'invalidMaximumUsage',
    );

    ruleFor(
      (request) => request['validUntil'] as String?,
      key: 'validUntil',
    ).must(
      RequestValidation.isValidDateTime,
      'validUntil must be in ISO8601 UTC format and not in the past',
      'invalidValidUntil',
    );
  }
}
