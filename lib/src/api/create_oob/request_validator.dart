import 'package:lucid_validation/lucid_validation.dart';

import '../request_validation.dart';

class CreateOobRequestValidator extends LucidValidator {
  CreateOobRequestValidator() {
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
      (request) => request['didcommMessage'] as String?,
      key: 'didcommMessage',
    ).notEmptyOrNull();
  }
}
