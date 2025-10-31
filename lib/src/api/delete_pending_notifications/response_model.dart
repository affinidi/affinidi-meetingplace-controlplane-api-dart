import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'response_model.g.dart';

@JsonSerializable()
class NotificationResponse {
  NotificationResponse({
    required this.id,
    required this.deviceHash,
    required this.did,
    required this.payload,
    this.offerLink,
  });
  final String id;
  final String deviceHash;
  final String did;
  final String payload;
  final String? offerLink;

  @override
  String toString() => jsonEncode(_$NotificationResponseToJson(this));

  toJson() => _$NotificationResponseToJson(this);

  static NotificationResponse fromJson(Map<String, dynamic> json) {
    return _$NotificationResponseFromJson(json);
  }
}

@JsonSerializable()
class DeletePendingNotificationsResponse {
  DeletePendingNotificationsResponse({
    required this.deletedIds,
    required this.notifications,
  });
  final List<String> deletedIds;
  final List<NotificationResponse> notifications;

  @override
  String toString() {
    Map json = _$DeletePendingNotificationsResponseToJson(this);
    json['notifications'] =
        json['notifications'].map((n) => n.toJson()).toList();
    return JsonEncoder().convert(json);
  }
}
