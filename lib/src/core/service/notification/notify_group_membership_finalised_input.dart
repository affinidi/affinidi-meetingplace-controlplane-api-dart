import '../../entity/acceptance.dart';

class NotifyGroupMembershipFinalisedInput {
  NotifyGroupMembershipFinalisedInput({
    required this.acceptance,
    required this.acceptOfferAsDid,
    required this.authDid,
    required this.startSeqNo,
  });
  final Acceptance acceptance;
  final String acceptOfferAsDid;
  final String authDid;
  final int startSeqNo;
}
