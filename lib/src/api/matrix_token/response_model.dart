import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'response_model.g.dart';

@JsonSerializable()
class MatrixTokenResponse {
  MatrixTokenResponse({required this.token});
  final String token;

  @override
  String toString() => jsonEncode(_$MatrixTokenResponseToJson(this));
}
