import '../config/config.dart';
import 'entity.dart';
import '../../utils/platform_type.dart';
import '../../utils/date_time.dart';
import 'package:json_annotation/json_annotation.dart';

part 'acceptance.g.dart';

enum Status {
  @JsonValue('CREATED')
  created('CREATED'),

  @JsonValue('DELETED')
  deleted('DELETED');

  const Status(this.value);

  final String value;
}

@JsonSerializable()
class Acceptance extends Entity {
  Acceptance({
    required this.id,
    required this.did,
    required this.offerLink,
    required this.contactCard,
    required this.status,
    required this.platformEndpointArn,
    required this.platformType,
    required this.mediatorDid,
    required this.mediatorEndpoint,
    required this.mediatorWSSEndpoint,
    required this.createdBy,
  }) {
    createdAt = nowUtc().toIso8601String();
    modifiedAt = nowUtc().toIso8601String();
    modifiedBy = createdBy;
  }

  @override
  factory Acceptance.fromJson(Map<String, dynamic> json) {
    return _$AcceptanceFromJson(json);
  }
  static String entityName = 'Acceptance';

  final String id;
  final String did;
  final String offerLink;
  final String contactCard;
  final Status status;
  final String platformEndpointArn;
  final PlatformType platformType;
  final int retries = Config().get('acceptance')['maximumRetries'];
  final String mediatorDid;
  final String mediatorEndpoint;
  final String mediatorWSSEndpoint;

  final String createdBy;
  late String modifiedBy;
  late String createdAt;
  late String modifiedAt;

  @override
  Map<String, dynamic> toJson() => _$AcceptanceToJson(this);

  @override
  String getId() => id;

  @override
  String getEntityName() => Acceptance.entityName;
}
