import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'response_model.g.dart';

@JsonSerializable()
class AuthChallengeResponse {
  AuthChallengeResponse({required this.challenge});
  final String challenge;

  @override
  String toString() =>
      JsonEncoder().convert(_$AuthChallengeResponseToJson(this));
}
