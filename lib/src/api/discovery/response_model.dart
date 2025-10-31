import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'response_model.g.dart';

@JsonSerializable()
class DiscoveryResponse {
  DiscoveryResponse({required this.token});
  final String token;

  @override
  String toString() => JsonEncoder().convert(
        _$DiscoveryResponseToJson(this),
      );
}
