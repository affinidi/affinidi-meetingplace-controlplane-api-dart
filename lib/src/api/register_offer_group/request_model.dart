import 'dart:convert';
import '../../utils/platform_type.dart';
import 'package:json_annotation/json_annotation.dart';

import '../request_validation_exception.dart';
import 'request_validator.dart';

part 'request_model.g.dart';

@JsonSerializable()
class RegisterOfferGroupRequest {
  factory RegisterOfferGroupRequest.fromRequestParams(String requestParams) {
    final params = jsonDecode(requestParams);

    final validationResult =
        RegisterOfferGroupRequestValidator().validate(params);

    if (!validationResult.isValid) {
      throw RequestValidationException.fromValidationResult(validationResult);
    }
    return _$RegisterOfferGroupRequestFromJson(params);
  }

  RegisterOfferGroupRequest({
    required this.offerName,
    required this.offerDescription,
    required this.didcommMessage,
    required this.vcard,
    required this.deviceToken,
    required this.platformType,
    required this.mediatorDid,
    required this.mediatorEndpoint,
    required this.mediatorWSSEndpoint,
    required this.adminReencryptionKey,
    required this.adminDid,
    required this.adminPublicKey,
    required this.memberVCard,
    this.validUntil,
    this.maximumUsage,
    this.customPhrase,
    this.metadata,
  });

  final String offerName;
  final String offerDescription;
  final String didcommMessage;
  final String vcard;
  final String? validUntil;
  final int? maximumUsage;
  final String deviceToken;
  final PlatformType platformType;
  final String mediatorDid;
  final String mediatorEndpoint;
  final String mediatorWSSEndpoint;
  final String adminReencryptionKey;
  final String adminDid;
  final String adminPublicKey;
  final String memberVCard;

  String? customPhrase;
  bool? isSearchable;
  String? metadata;

  toJson() => _$RegisterOfferGroupRequestToJson(this);
}
