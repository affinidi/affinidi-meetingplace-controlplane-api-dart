import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'response_model.g.dart';

@JsonSerializable()
class MatrixRegistrationCredentialResponse {
  MatrixRegistrationCredentialResponse({
    required this.credential,
    required this.did,
  });

  final String credential;
  final String did;

  @override
  String toString() =>
      JsonEncoder().convert(_$MatrixRegistrationCredentialResponseToJson(this));
}
