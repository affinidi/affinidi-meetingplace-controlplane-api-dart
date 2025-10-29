import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'response_model.g.dart';

@JsonSerializable()
class GroupSendMessageResponse {
  GroupSendMessageResponse({required this.status, required this.message});
  final String status;
  final String message;

  @override
  String toString() => jsonEncode(_$GroupSendMessageResponseToJson(this));
}
