import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'response_model.g.dart';

@JsonSerializable()
class CreateOobResponse {
  CreateOobResponse({required this.oobId, required this.oobUrl});
  final String oobId;
  final String oobUrl;

  @override
  String toString() => JsonEncoder().convert(_$CreateOobResponseToJson(this));
}
