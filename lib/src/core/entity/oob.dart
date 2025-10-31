import 'entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'oob.g.dart';

@JsonSerializable()
class Oob extends Entity {
  @override
  factory Oob.fromJson(Map<String, dynamic> json) => _$OobFromJson(json);

  Oob({
    required super.ttl,
    required this.oobId,
    required this.didcommMessage,
    required this.mediatorDid,
    required this.mediatorEndpoint,
    required this.mediatorWSSEndpoint,
  });
  static String entityName = 'Oob';

  final String oobId;
  final String didcommMessage;
  final String mediatorDid;
  final String mediatorEndpoint;
  final String mediatorWSSEndpoint;

  @override
  Map<String, dynamic> toJson() => _$OobToJson(this);

  @override
  String getId() => oobId;

  @override
  String getEntityName() => entityName;
}
