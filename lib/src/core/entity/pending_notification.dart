import 'entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pending_notification.g.dart';

@JsonSerializable()
class PendingNotification extends Entity {
  @override
  factory PendingNotification.fromJson(Map<String, dynamic> json) =>
      _$PendingNotificationFromJson(json);

  PendingNotification({super.ttl, required this.id, required this.deviceHash});

  static String entityName = 'PendingNotification';

  final String id;
  final String deviceHash;

  @override
  Map<String, dynamic> toJson() => _$PendingNotificationToJson(this);

  @override
  String getId() => id;

  @override
  String? getListId() => deviceHash;

  @override
  String getEntityName() => PendingNotification.entityName;
}
