import '../../meeting_place_control_plane_api.dart';

bool isAdmin(String did) {
  final whitelist = (getEnvOrNull('ADMIN_WHITELIST') ?? '').split(',');
  return whitelist.contains(did);
}
