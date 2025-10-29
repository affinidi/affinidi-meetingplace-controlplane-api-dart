import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'response_model.g.dart';

@JsonSerializable()
class FinaliseAcceptanceResponse {
  FinaliseAcceptanceResponse({required this.notificationToken});
  final String? notificationToken;

  @override
  String toString() =>
      JsonEncoder().convert(_$FinaliseAcceptanceResponseToJson(this));
}
