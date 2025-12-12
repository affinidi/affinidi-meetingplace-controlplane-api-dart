import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'response_model.g.dart';

@JsonSerializable()
class DeregisterNotificationResponse {
  DeregisterNotificationResponse({required this.status});
  final String status;

  @override
  String toString() =>
      JsonEncoder().convert(_$DeregisterNotificationResponseToJson(this));
}
