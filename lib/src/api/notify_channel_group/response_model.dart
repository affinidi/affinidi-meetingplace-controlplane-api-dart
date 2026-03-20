import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'response_model.g.dart';

@JsonSerializable()
class NotifyChannelGroupResponse {
  NotifyChannelGroupResponse({required this.notifiedCount});

  final int notifiedCount;

  @override
  String toString() =>
      JsonEncoder().convert(_$NotifyChannelGroupResponseToJson(this));
}
