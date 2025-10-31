import 'entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group.g.dart';

enum GroupStatus {
  @JsonValue('CREATED')
  created('CREATED'),

  @JsonValue('DELETED')
  deleted('DELETED');

  const GroupStatus(this.value);

  final String value;
}

@JsonSerializable()
class Group extends Entity {
  @override
  factory Group.fromJson(Map<String, dynamic> json) => _$GroupFromJson(json);

  Group({
    super.ttl,
    required this.id,
    required this.offerLink,
    required this.groupDid,
    required this.conrollingDid,
    required this.name,
    required this.mediatorDid,
    required this.createdBy,
    required this.modifiedBy,
    required this.status,
    required this.seqNo,
  });
  static String entityName = 'Group';

  final String id;
  final String offerLink;
  final String groupDid;
  final String name;
  final String mediatorDid;
  final String conrollingDid;
  final String createdBy;
  final String modifiedBy;
  GroupStatus status;
  int seqNo;

  @override
  Map<String, dynamic> toJson() => _$GroupToJson(this);

  @override
  String getId() => id;

  @override
  String getEntityName() => Group.entityName;

  Group incrementSeqNo() {
    seqNo = seqNo + 1;
    return this;
  }
}
