import 'package:lucid_validation/lucid_validation.dart';

class UpdateOffersScoreRequestValidator extends LucidValidator {
  UpdateOffersScoreRequestValidator() {
    ruleFor((request) => request['score'] as int?, key: 'score')
        .must((v) => v != null, 'Score is required', 'missingScore')
        .must((v) => v! >= 0, 'Score must be non-negative', 'invalidScore');

    ruleFor((request) => request['mnemonics'], key: 'mnemonics').must(
      (v) {
        return v != null &&
            (v is List &&
                v.isNotEmpty &&
                v.every((item) => item is String && item.trim().isNotEmpty));
      },
      'mnemonics must be a non-empty list of valid strings',
      'invalidMnemonicsType',
    );
  }
}
