enum NotificationStackGroupingTypes {
  invitationAccept('mpx-invitation-accept'),
  invitationOutreach('mpx-invitation-outreach'),
  offerFinalised('mpx-offer-finalised'),
  groupMembershipFinalised('mpx-group-membership-finalised'),
  channelActivity('mpx-channel-activity');

  const NotificationStackGroupingTypes(this.value);
  final String value;
}
