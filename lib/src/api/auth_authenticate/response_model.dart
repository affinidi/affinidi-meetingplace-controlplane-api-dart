import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'response_model.g.dart';

@JsonSerializable()
class AuthAuthenticateResponse {
  AuthAuthenticateResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresAt,
    required this.refreshExpiresAt,
  });
  @JsonKey(name: 'access_token')
  final String accessToken;

  @JsonKey(name: 'refresh_token')
  final String refreshToken;

  @JsonKey(toJson: _dateTimeToJson, name: 'access_expires_at')
  final DateTime accessExpiresAt;

  @JsonKey(toJson: _dateTimeToJson, name: 'refresh_expires_at')
  final DateTime refreshExpiresAt;

  @override
  String toString() =>
      JsonEncoder().convert(_$AuthAuthenticateResponseToJson(this));

  static _dateTimeToJson(DateTime value) => value.toIso8601String();
}
