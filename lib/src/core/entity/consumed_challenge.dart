import 'entity.dart';

class ConsumedChallenge extends Entity {
  ConsumedChallenge({required this.jti, required super.ttl});

  factory ConsumedChallenge.fromJson(Map<String, dynamic> json) =>
      ConsumedChallenge(jti: json['jti'] as String, ttl: null);

  static const entityName = 'ConsumedChallenge';

  final String jti;

  @override
  String getId() => jti;

  @override
  String getEntityName() => entityName;

  @override
  Map<String, dynamic> toJson() => {'jti': jti};
}
