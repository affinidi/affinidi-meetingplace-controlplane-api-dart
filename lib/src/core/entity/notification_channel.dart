import 'entity.dart';
import '../../utils/platform_type.dart';
import 'package:json_annotation/json_annotation.dart';

part 'notification_channel.g.dart';

enum Status {
  @JsonValue('CREATED')
  created('CREATED'),

  @JsonValue('DELETED')
  deleted('DELETED');

  const Status(this.value);

  final String value;
}

@JsonSerializable()
class NotificationChannel extends Entity {
  NotificationChannel({
    required this.notificationChannelId,
    required this.did,
    required this.peerDid,
    required this.platformEndpointArn,
    required this.platformType,
    required this.createdBy,
  }) {
    modifiedBy = createdBy;
  }

  @override
  factory NotificationChannel.fromJson(Map<String, dynamic> json) =>
      _$NotificationChannelFromJson(json);
  static String entityName = 'NotificationChannel';

  late String notificationChannelId;
  final String did;
  final String peerDid;

  final Status status = Status.created;
  final String platformEndpointArn;
  final PlatformType platformType;

  final String createdBy;
  late String modifiedBy;

  @override
  Map<String, dynamic> toJson() => _$NotificationChannelToJson(this);

  @override
  String getId() => notificationChannelId;

  @override
  String getEntityName() => entityName;
}
