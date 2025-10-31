import 'package:json_annotation/json_annotation.dart';

part 'create_group_input.g.dart';

@JsonSerializable()
class CreateGroupInput {
  CreateGroupInput({
    required this.offerLink,
    required this.groupName,
    required this.mediatorDid,
    required this.controllingDid,
    required this.createdBy,
    required this.modifiedBy,
  });

  factory CreateGroupInput.fromJson(Map<String, dynamic> json) =>
      _$CreateGroupInputFromJson(json);
  final String offerLink;
  final String groupName;
  final String mediatorDid;
  final String controllingDid;
  final String createdBy;
  final String modifiedBy;
}
