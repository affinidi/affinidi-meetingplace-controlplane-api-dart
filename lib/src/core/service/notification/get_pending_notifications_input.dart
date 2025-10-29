import '../../../utils/platform_type.dart';

class GetPendingNotificationsInput {
  GetPendingNotificationsInput({
    required this.platformType,
    required this.deviceToken,
  });

  final PlatformType platformType;
  final String deviceToken;
}
