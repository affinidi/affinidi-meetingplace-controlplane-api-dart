import '../../entity/acceptance.dart';
import '../../entity/offer.dart';

class NotifyAcceptanceInput {
  NotifyAcceptanceInput({
    required this.offer,
    required this.acceptance,
    required this.didUsedForAcceptance,
    required this.senderInfo,
    required this.authDid,
  });

  final Offer offer;
  final Acceptance acceptance;
  final String didUsedForAcceptance;
  final String senderInfo;
  final String authDid;
}
