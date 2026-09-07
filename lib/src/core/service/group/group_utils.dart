import 'package:uuid/uuid.dart';

import '../../config/config.dart';
import '../../../utils/hash.dart';

class GroupUtils {
  static String normalizeBase64(String base64String) {
    // Remove any whitespace or newlines
    base64String = base64String.trim();

    // Calculate how many '=' are needed to make length a multiple of 4
    int paddingNeeded = base64String.length % 4;
    if (paddingNeeded > 0) {
      base64String += '=' * (4 - paddingNeeded);
    }

    return base64String;
  }

  /// Mixes in a fresh UUID so groups created for the same [offerLink] never
  /// collide.
  static String generateGroupId({required String offerLink}) {
    return generateHashedId(
      '${offerLink}_${Uuid().v4()}',
      Config().hashSecret(),
    );
  }
}
