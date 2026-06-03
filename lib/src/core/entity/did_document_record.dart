import 'entity.dart';

class DidDocumentRecord extends Entity {
  DidDocumentRecord({
    required this.did,
    required this.createdBy,
    required this.createdByVerificationMethod,
    required this.createdAt,
    required this.updatedAt,
    required this.didDocument,
  });

  factory DidDocumentRecord.fromJson(Map<String, dynamic> json) {
    final didDocument = json['didDocument'];
    if (didDocument is! Map) {
      throw FormatException('didDocument must be a JSON object');
    }

    return DidDocumentRecord(
      did: json['did'] as String,
      createdBy: json['createdBy'] as String,
      createdByVerificationMethod:
          json['createdByVerificationMethod'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      didDocument: Map<String, dynamic>.from(didDocument),
    );
  }

  final String did;
  final String createdBy;
  final String createdByVerificationMethod;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> didDocument;

  String get segment => did.split(':').last;

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
      'createdByVerificationMethod': createdByVerificationMethod,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'didDocument': didDocument,
    };
  }
}
