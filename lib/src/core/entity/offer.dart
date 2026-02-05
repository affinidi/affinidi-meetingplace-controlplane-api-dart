import 'entity.dart';
import '../../utils/platform_type.dart';
import 'package:json_annotation/json_annotation.dart';

part 'offer.g.dart';

enum OfferStatus {
  @JsonValue('CREATED')
  created('CREATED'),

  @JsonValue('DELETED')
  deleted('DELETED');

  const OfferStatus(this.value);

  final String value;
}

enum OfferType {
  @JsonValue('UNSPECIFIED')
  unspecified('UNSPECIFIED'),

  @JsonValue('CHAT')
  chat('CHAT'),

  @JsonValue('POLL')
  poll('POLL'),

  @JsonValue('GROUP')
  group('GROUP'),

  @JsonValue('OUTREACH')
  outreach('OUTREACH');

  const OfferType(this.value);

  final String value;
}

@JsonSerializable()
class Offer extends Entity {
  Offer({
    required super.ttl,
    required this.id,
    required this.name,
    required this.description,
    required this.offerType,
    required this.didcommMessage,
    required this.contactCard,
    required this.platformEndpointArn,
    required this.platformType,
    required this.mediatorDid,
    required this.mediatorEndpoint,
    required this.mediatorWSSEndpoint,
    required this.mnemonic,
    required this.offerLink,
    required this.contactAttributes,
    required this.createdBy,
    this.maximumClaims,
    this.maximumQueries,
    this.validUntil,
    this.customPhrase,
    this.metadata,
    this.groupId,
    this.groupDid,
    this.score,
  }) {
    createdAt = DateTime.now().toIso8601String();
    modifiedAt = DateTime.now().toIso8601String();
    modifiedBy = createdBy;
  }

  @override
  factory Offer.fromJson(Map<String, dynamic> json) => _$OfferFromJson(json);
  static String entityName = 'Offer';

  final String id;
  final String name;
  final String description;
  final String didcommMessage;
  final String contactCard;
  final String mnemonic;
  final String offerLink;
  final OfferType offerType;
  final OfferStatus status = OfferStatus.created;
  final int contactAttributes;
  final String? validUntil;
  final String? customPhrase;
  final String? metadata;

  int? score;
  String? groupId;
  String? groupDid;

  int queryCount = 0;
  int claimCount = 0;

  final int? maximumClaims;
  final int? maximumQueries;

  final String platformEndpointArn;
  final PlatformType platformType;

  final String mediatorDid;
  final String mediatorEndpoint;
  final String mediatorWSSEndpoint;

  final String createdBy;
  late String modifiedBy;
  late String createdAt;
  late String modifiedAt;

  @override
  Map<String, dynamic> toJson() => _$OfferToJson(this);

  @override
  String getId() => id;

  @override
  String getEntityName() => Offer.entityName;

  Offer increaseQueryCount() {
    queryCount = queryCount + 1;
    return this;
  }

  Offer increaseClaimCount() {
    claimCount = claimCount + 1;
    return this;
  }
}
