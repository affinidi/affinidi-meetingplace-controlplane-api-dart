import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'response_model.g.dart';

@JsonSerializable()
class GroupMemberDeregisterReponse {
  GroupMemberDeregisterReponse({required this.status, required this.message});
  final String status;
  final String message;

  @override
  String toString() => jsonEncode(_$GroupMemberDeregisterReponseToJson(this));
}
