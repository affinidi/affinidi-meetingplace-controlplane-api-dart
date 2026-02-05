import '../../core/entity/offer.dart';

class UpdateOffersScoreResult {
  UpdateOffersScoreResult({
    required this.updatedOffers,
    required this.unauthorizedMnemonics,
  });

  final List<Offer> updatedOffers;
  final List<String> unauthorizedMnemonics;
}
