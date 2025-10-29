import 'dart:convert';
import '../../core/entity/oob.dart';
import 'package:json_annotation/json_annotation.dart';

part 'response_model.g.dart';

@JsonSerializable()
class GetOobResponse {
  GetOobResponse({
    required this.oobId,
    required this.didcommMessage,
    required this.mediatorDid,
    required this.mediatorEndpoint,
    required this.mediatorWSSEndpoint,
  });

  factory GetOobResponse.fromOob(Oob oob) {
    return GetOobResponse(
      oobId: oob.oobId,
      didcommMessage: oob.didcommMessage,
      mediatorDid: oob.mediatorDid,
      mediatorEndpoint: oob.mediatorEndpoint,
      mediatorWSSEndpoint: oob.mediatorWSSEndpoint,
    );
  }
  final String oobId;
  final String didcommMessage;
  final String mediatorDid;
  final String mediatorEndpoint;
  final String mediatorWSSEndpoint;

  @override
  String toString() => JsonEncoder().convert(_$GetOobResponseToJson(this));
}
