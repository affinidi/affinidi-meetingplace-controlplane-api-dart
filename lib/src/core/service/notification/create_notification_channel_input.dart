import '../../../utils/platform_type.dart';

class CreateNotificationChannelInput {
  CreateNotificationChannelInput({
    required this.didUsedForAcceptance,
    required this.theirDid,
    required this.deviceToken,
    required this.platformType,
  });
  final String didUsedForAcceptance;
  final String theirDid;
  final String deviceToken;
  final PlatformType platformType;
}
