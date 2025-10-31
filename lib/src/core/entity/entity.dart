abstract class Entity {
  Entity({this.ttl});
  DateTime? ttl;

  String getId();
  String getEntityName();
  Map<String, dynamic> toJson();

  String? getListId() => null;
}
