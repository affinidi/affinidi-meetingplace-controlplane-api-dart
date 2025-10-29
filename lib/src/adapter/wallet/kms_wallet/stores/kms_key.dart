import 'package:json_annotation/json_annotation.dart';
import '../../../../core/entity/entity.dart';

part 'kms_key.g.dart';

@JsonSerializable()
class KmsKey extends Entity {
  @override
  factory KmsKey.fromJson(Map<String, dynamic> json) {
    return _$KmsKeyFromJson(json);
  }

  KmsKey({super.ttl, required this.keyId, required this.publicKey});
  static String entityName = 'KmsKey';

  final String keyId;
  final String publicKey;

  @override
  Map<String, dynamic> toJson() => _$KmsKeyToJson(this);

  @override
  String getId() => keyId;

  @override
  String getEntityName() => KmsKey.entityName;
}
