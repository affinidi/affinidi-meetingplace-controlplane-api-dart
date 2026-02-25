import 'entity.dart';
import '../../utils/platform_type.dart';
import '../../utils/date_time.dart';
import 'package:json_annotation/json_annotation.dart';

part 'device_token_mapping.g.dart';

@JsonSerializable()
class DeviceTokenMapping extends Entity {
  factory DeviceTokenMapping.fromJson(Map<String, dynamic> json) {
    return _$DeviceTokenMappingFromJson(json);
  }

  factory DeviceTokenMapping.noPlatform() {
    return DeviceTokenMapping(
      deviceId: 'NONE',
      deviceToken: 'NONE',
      platformType: PlatformType.NONE,
      platformEndpointArn: 'NONE',
    );
  }

  DeviceTokenMapping({
    required this.deviceId,
    required this.deviceToken,
    required this.platformType,
    required this.platformEndpointArn,
    this.createdBy,
  }) : createdAt = nowUtc().toIso8601String(),
       modifiedAt = nowUtc().toIso8601String(),
       modifiedBy = createdBy;
  static String entityName = 'DeviceTokenMapping';

  final String deviceId;
  final String deviceToken;
  final PlatformType platformType;
  final String platformEndpointArn;
  final String? createdBy;
  final String createdAt;
  final String modifiedAt;
  final String? modifiedBy;

  @override
  Map<String, dynamic> toJson() => _$DeviceTokenMappingToJson(this);

  @override
  String getEntityName() => DeviceTokenMapping.entityName;

  @override
  String getId() => deviceId;
}
