import 'response_model.dart';

class UpdateOffersScoreResult {
  UpdateOffersScoreResult({
    required this.updatedOffers,
    required this.failedOffers,
  });

  final List<String> updatedOffers;
  final List<FailedOffer> failedOffers;
}
