import '../../entity/acceptance.dart';
import '../../../utils/platform_type.dart';

class NotifyFinaliseAcceptanceInput {
  NotifyFinaliseAcceptanceInput({
    required this.acceptance,
    required this.didUsedForAcceptance,
    required this.theirDid,
    required this.authDid,
    this.deviceToken,
    this.platformType,
  });
  final Acceptance acceptance;
  final String didUsedForAcceptance;
  final String theirDid;
  final String authDid;
  final String? deviceToken;
  final PlatformType? platformType;
}
