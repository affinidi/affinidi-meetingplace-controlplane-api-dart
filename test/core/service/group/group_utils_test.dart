import 'package:meeting_place_control_plane_api/src/core/config/config.dart';
import 'package:meeting_place_control_plane_api/src/core/service/group/group_utils.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    Config().registerSecret('hashSecret', {'secret': 'test-secret'});
  });

  group('GroupUtils.generateGroupId', () {
    test(
      'returns different ids for repeated calls with the same offerLink',
      () {
        const offerLink = 'https://example.com/offer/123';

        final firstId = GroupUtils.generateGroupId(offerLink: offerLink);
        final secondId = GroupUtils.generateGroupId(offerLink: offerLink);

        expect(firstId, isNot(equals(secondId)));
      },
    );
  });
}
