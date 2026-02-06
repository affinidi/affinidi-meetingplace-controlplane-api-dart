import '../../core/entity/offer.dart';
import 'response_model.dart';

class UpdateOffersScoreResult {
  UpdateOffersScoreResult({
    required this.updatedOffers,
    required this.failedOffers,
  });

  final List<Offer> updatedOffers;
  final List<FailedOffer> failedOffers;
}
