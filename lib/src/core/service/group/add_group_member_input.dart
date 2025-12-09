import 'package:json_annotation/json_annotation.dart';

import '../../../utils/platform_type.dart';

part 'add_group_member_input.g.dart';

@JsonSerializable()
class AddGroupMemberInput {
  factory AddGroupMemberInput.fromJson(Map<String, dynamic> json) =>
      _$AddGroupMemberInputFromJson(json);

  AddGroupMemberInput({
    required this.groupId,
    required this.offerLink,
    required this.memberDid,
    required this.memberPublicKey,
    required this.memberReencryptionKey,
    required this.memberContactCard,
    required this.platformType,
    required this.platformEndpointArn,
    required this.controllingDid,
    required this.authDid,
  });

  final String groupId;
  final String offerLink;
  final String memberDid;
  final String memberPublicKey;
  final String memberReencryptionKey;
  final String memberContactCard;
  final PlatformType platformType;
  final String platformEndpointArn;
  final String controllingDid;
  final String authDid;
}
