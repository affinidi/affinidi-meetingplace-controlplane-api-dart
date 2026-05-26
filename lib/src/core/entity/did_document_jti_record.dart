import 'entity.dart';

class DidDocumentJtiRecord extends Entity {
  DidDocumentJtiRecord({
    required this.did,
    required this.jti,
    required this.expiresAt,
    required this.proofPurpose,
    required this.operation,
  });

  factory DidDocumentJtiRecord.fromJson(Map<String, dynamic> json) {
    return DidDocumentJtiRecord(
      did: json['did'] as String,
      jti: json['jti'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      proofPurpose: json['proofPurpose'] as String,
      operation: json['operation'] as String,
    );
  }

  final String did;
  final String jti;
  final DateTime expiresAt;
  final String proofPurpose;
  final String operation;

  static String entityName = 'DidDocumentJTI';

  @override
  String getEntityName() => entityName;

  @override
  String getId() => '$did::$jti';

  @override
  Map<String, dynamic> toJson() {
    return {
      'did': did,
      'jti': jti,
      'expiresAt': expiresAt.toUtc().toIso8601String(),
      'proofPurpose': proofPurpose,
      'operation': operation,
    };
  }
}
