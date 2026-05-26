import 'entity.dart';

class DidDocumentSegmentRecord extends Entity {
  DidDocumentSegmentRecord({required this.segment, required this.did});

  factory DidDocumentSegmentRecord.fromJson(Map<String, dynamic> json) {
    return DidDocumentSegmentRecord(
      segment: json['segment'] as String,
      did: json['did'] as String,
    );
  }

  final String segment;
  final String did;

  static String entityName = 'DidDocumentSegment';

  @override
  String getEntityName() => entityName;

  @override
  String getId() => segment;

  @override
  Map<String, dynamic> toJson() {
    return {'segment': segment, 'did': did};
  }
}
