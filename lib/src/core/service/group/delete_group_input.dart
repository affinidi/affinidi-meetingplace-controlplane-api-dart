import 'package:json_annotation/json_annotation.dart';

part 'delete_group_input.g.dart';

@JsonSerializable()
class DeleteGroupInput {
  DeleteGroupInput({
    required this.groupId,
    required this.messageToRelay,
    required this.controllingDid,
  });

  factory DeleteGroupInput.fromJson(Map<String, dynamic> json) =>
      _$DeleteGroupInputFromJson(json);

  final String groupId;
  final String messageToRelay;
  final String controllingDid;
}
