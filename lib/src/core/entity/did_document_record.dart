import 'entity.dart';

class DidDocumentRecord extends Entity {
  DidDocumentRecord({
    required this.did,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.didDocument,
  });

  factory DidDocumentRecord.fromJson(Map<String, dynamic> json) {
    return DidDocumentRecord(
      did: json['did'] as String,
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      didDocument: Map<String, dynamic>.from(
        (json['didDocument'] as Map?) ?? <String, dynamic>{},
      ),
    );
  }

  final String did;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> didDocument;

  static String entityName = 'DidDocument';

  @override
  String getEntityName() => entityName;

  @override
  String getId() => did;

  @override
  Map<String, dynamic> toJson() {
    return {
      'did': did,
      'createdBy': createdBy,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'didDocument': didDocument,
    };
  }
}
