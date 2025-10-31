import '../../entity/offer.dart';

class NotifyOutreachInput {
  NotifyOutreachInput({required this.offer, required this.senderInfo});

  final Offer offer;
  final String senderInfo;
}
