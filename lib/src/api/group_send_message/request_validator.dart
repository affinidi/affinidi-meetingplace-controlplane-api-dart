import 'package:lucid_validation/lucid_validation.dart';

class GroupSendMessageValidator extends LucidValidator {
  GroupSendMessageValidator() {
    ruleFor(
      (request) => request['offerLink'] as String?,
      key: 'offerLink',
    ).notEmptyOrNull();

    ruleFor(
      (request) => request['groupDid'] as String?,
      key: 'groupDid',
    ).notEmptyOrNull();

    ruleFor(
      (request) => request['payload'] as String?,
      key: 'payload',
    ).notEmptyOrNull();

    ruleFor((request) => request['ephemeral'], key: 'ephemeral').must(
      (value) => value != null,
      'ephemeral is required',
      'ephemeral_required',
    );

    ruleFor((request) => request['expiresTime'], key: 'expiresTime').must(
      (value) => value == null || value.isNotEmpty,
      'expiresTime must not be empty if provided',
      'invalid_expires_time',
    );
  }
}
