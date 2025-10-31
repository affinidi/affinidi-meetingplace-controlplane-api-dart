import 'package:json_annotation/json_annotation.dart';

import 'entity.dart';

part 'key_reference.g.dart';

@JsonSerializable()
class KeyReference extends Entity {
  KeyReference({
    required this.keyId,
    required this.entityId,
  });

  @override
  factory KeyReference.fromJson(Map<String, dynamic> json) {
    return _$KeyReferenceFromJson(json);
  }
  static String entityName = 'KeyReference';

  final String keyId;
  final String entityId;

  @override
  Map<String, dynamic> toJson() => _$KeyReferenceToJson(this);

  @override
  String getId() => entityId;

  @override
  String getEntityName() => KeyReference.entityName;
}
