import 'entity.dart';
import '../../utils/platform_type.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group_member.g.dart';

@JsonSerializable()
class GroupMember extends Entity {
  @override
  factory GroupMember.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberFromJson(json);

  GroupMember({
    required this.groupId,
    required this.offerLink,
    required this.memberDid,
    required this.memberPublicKey,
    required this.memberReencryptionKey,
    required this.memberContactCard,
    required this.platformEndpointArn,
    required this.platformType,
    required this.controllingDid,
    required this.startSeqNo,
    super.ttl,
  });
  static String entityName = 'GroupMember';

  final String groupId;
  final String offerLink;
  final String memberDid;
  final String memberPublicKey;
  final String memberReencryptionKey;
  final String memberContactCard;
  final String platformEndpointArn;
  final PlatformType platformType;
  final String controllingDid;
  final int startSeqNo;

  @override
  Map<String, dynamic> toJson() => _$GroupMemberToJson(this);

  @override
  String getId() => memberDid;

  @override
  String getListId() => groupId;

  @override
  String getEntityName() => GroupMember.entityName;
}
