import '../../config/config.dart';
import 'register_device_input.dart';
import '../../storage/storage.dart';
import '../../../utils/hash.dart';
import '../../../utils/platform_type.dart';
import '../../entity/device_token_mapping.dart';

class DeviceTokenMappingNotFound implements Exception {
  DeviceTokenMappingNotFound(this.message);
  final String message;
}

class DeviceTokenMappingService {
  DeviceTokenMappingService(this._storage);
  final Storage _storage;

  Future<DeviceTokenMapping> getDeviceTokenMapping({
    required PlatformType devicePlatform,
    required String deviceToken,
  }) async {
    if (devicePlatform == PlatformType.NONE) {
      return DeviceTokenMapping.noPlatform();
    }

    final tokenMappingId = _generateDeviceTokenMappingIdForEndpointMapping(
      devicePlatform: devicePlatform,
      deviceToken: deviceToken,
    );

    final deviceTokenMapping = await _storage.findOneById(
      DeviceTokenMapping.entityName,
      tokenMappingId,
      DeviceTokenMapping.fromJson,
    );

    if (deviceTokenMapping == null) {
      throw DeviceTokenMappingNotFound('Device token mapping not found.');
    }

    return deviceTokenMapping;
  }

  Future<DeviceTokenMapping> createMapping(
    RegisterDeviceInput input,
    String authDid,
  ) async {
    final tokenMappingId = _generateDeviceTokenMappingIdForEndpointMapping(
      devicePlatform: input.platformType,
      deviceToken: input.deviceToken,
    );

    return _storage.update(
      DeviceTokenMapping(
        deviceId: tokenMappingId,
        deviceToken: input.deviceToken,
        platformType: input.platformType,
        platformEndpointArn: input.platformEndpointArn,
        createdBy: authDid,
      ),
    );
  }

  String generateDeviceHash(String platformEndpointArn) {
    return generateHashedId(platformEndpointArn, Config().hashSecret());
  }

  String _generateDeviceTokenMappingIdForEndpointMapping({
    required PlatformType devicePlatform,
    required String deviceToken,
  }) {
    return generateHashedId(
      '${devicePlatform}_$deviceToken',
      Config().hashSecret(),
    );
  }
}
