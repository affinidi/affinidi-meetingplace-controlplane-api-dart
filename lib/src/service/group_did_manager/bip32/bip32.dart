import 'package:json_annotation/json_annotation.dart';

import '../../../core/entity/entity.dart';

part 'bip32.g.dart';

@JsonSerializable()
class Bip32 extends Entity {
  Bip32({super.ttl, required this.accountingIndex});
  final String id = 'accountIndex';
  String accountingIndex;

  static final String entityName = 'Bip32';

  @override
  String getEntityName() {
    return entityName;
  }

  @override
  String getId() {
    return id;
  }

  @override
  Map<String, dynamic> toJson() {
    return _$Bip32ToJson(this);
  }

  static Bip32 fromJson(Map<String, dynamic> json) {
    return _$Bip32FromJson(json);
  }
}
