import '../../../utils/platform_type.dart';

class RegisterDeviceInput {
  RegisterDeviceInput({
    required this.deviceToken,
    required this.platformType,
    required this.platformEndpointArn,
  });
  final String deviceToken;
  final PlatformType platformType;
  final String platformEndpointArn;
}
