import 'package:lucid_validation/lucid_validation.dart';

class UpdateOffersScoreRequestValidator extends LucidValidator {
  UpdateOffersScoreRequestValidator() {
    ruleFor((request) => request['score'] as int?, key: 'score')
        .must((v) => v != null, 'Score is required', 'missingScore')
        .must((v) => v is int, 'Score must be an integer', 'invalidScoreType')
        .must(
          (v) => v != null && v >= 0,
          'Score must be non-negative',
          'invalidScore',
        );

    ruleFor(
          (request) => request['offerLinks'] as List<dynamic>?,
          key: 'offerLinks',
        )
        .must((v) => v != null, 'offerLinks is required', 'missingOfferLinks')
        .must(
          (v) => v is List && v.isNotEmpty,
          'offerLinks must not be empty',
          'emptyOfferLinks',
        );
  }
}
