import 'package:lucid_validation/lucid_validation.dart';

class GroupAddMemberRequestValidator extends LucidValidator {
  GroupAddMemberRequestValidator() {
    ruleFor(
      (request) => request['offerLink'] as String?,
      key: 'offerLink',
    ).notEmptyOrNull();

    ruleFor(
      (request) => request['mnemonic'] as String?,
      key: 'mnemonic',
    ).notEmptyOrNull();

    ruleFor(
      (request) => request['groupId'] as String?,
      key: 'groupId',
    ).notEmptyOrNull();

    ruleFor(
      (request) => request['memberDid'] as String?,
      key: 'memberDid',
    ).notEmptyOrNull();

    ruleFor(
      (request) => request['acceptOfferAsDid'] as String?,
      key: 'acceptOfferAsDid',
    ).notEmptyOrNull();

    ruleFor(
      (request) => request['reencryptionKey'] as String?,
      key: 'reencryptionKey',
    ).notEmptyOrNull();

    ruleFor(
      (request) => request['publicKey'] as String?,
      key: 'publicKey',
    ).notEmptyOrNull();
  }
}
