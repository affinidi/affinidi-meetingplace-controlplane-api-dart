import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../request_validation_exception.dart';
import 'request_validator.dart';

part 'request_model.g.dart';

@JsonSerializable()
class GroupAddMemberRequest {
  factory GroupAddMemberRequest.fromRequestParams(String requestParams) {
    final params = jsonDecode(requestParams);

    final validationResult = GroupAddMemberRequestValidator().validate(params);

    if (!validationResult.isValid) {
      throw RequestValidationException.fromValidationResult(validationResult);
    }

    return _$GroupAddMemberRequestFromJson(params);
  }

  GroupAddMemberRequest({
    required this.offerLink,
    required this.mnemonic,
    required this.groupId,
    required this.memberDid,
    required this.acceptOfferAsDid,
    required this.reencryptionKey,
    required this.publicKey,
    required this.contactCard,
  });
  final String offerLink;
  final String mnemonic;
  final String groupId;
  final String memberDid;
  final String acceptOfferAsDid;
  final String reencryptionKey;
  final String publicKey;
  final String contactCard;

  toJson() => _$GroupAddMemberRequestToJson(this);
}
