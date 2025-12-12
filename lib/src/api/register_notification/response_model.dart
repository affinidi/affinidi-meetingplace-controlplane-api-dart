import 'dart:convert';
import '../../core/entity/notification_channel.dart';
import 'package:json_annotation/json_annotation.dart';

part 'response_model.g.dart';

@JsonSerializable()
class RegisterNotificationResponse {
  RegisterNotificationResponse({required this.notificationToken});

  factory RegisterNotificationResponse.fromNotificationChannel(
    NotificationChannel notificationChannel,
  ) {
    return RegisterNotificationResponse(
      notificationToken: notificationChannel.getId(),
    );
  }
  final String notificationToken;

  @override
  String toString() =>
      JsonEncoder().convert(_$RegisterNotificationResponseToJson(this));
}
