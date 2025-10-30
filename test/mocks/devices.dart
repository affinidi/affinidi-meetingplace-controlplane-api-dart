import 'package:meeting_place_control_plane_api/src/utils/platform_type.dart';
import 'package:uuid/uuid.dart';

class AliceDevice {
  static String deviceToken = Uuid().v4();
  static PlatformType platformType = PlatformType.PUSH_NOTIFICATION;
}

class BobDevice {
  static String offerAcceptanceDid =
      'did:key:zQ3shiDdnwQ4UoAvobWaPLxpXPCjS9928LyK8BujBbrw1PfpM';

  static String deviceToken = Uuid().v4();
  static PlatformType platformType = PlatformType.PUSH_NOTIFICATION;
}

class CharlieDevice {
  static String deviceToken = Uuid().v4();
  static PlatformType platformType = PlatformType.PUSH_NOTIFICATION;
}
