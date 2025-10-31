import 'dart:convert';
import '../../utils/platform_type.dart';
import 'package:json_annotation/json_annotation.dart';

part 'response_model.g.dart';

enum ResponseStatus {
  @JsonValue('SUCCEEDED')
  succeeded('SUCCEEDED'),

  @JsonValue('ERROR')
  error('ERROR');

  const ResponseStatus(this.value);

  final String value;
}

@JsonSerializable()
class RegisterDeviceResponse {
  factory RegisterDeviceResponse.success({
    required String deviceToken,
    required PlatformType platformType,
  }) {
    return RegisterDeviceResponse(
      status: ResponseStatus.succeeded.value,
      message: 'Device registration succeeded',
      deviceToken: deviceToken,
      platformType: platformType,
    );
  }

  factory RegisterDeviceResponse.error() {
    return RegisterDeviceResponse(
      status: ResponseStatus.error.value,
      message: 'An error occurred during processing',
    );
  }

  RegisterDeviceResponse({
    required this.status,
    required this.message,
    this.deviceToken,
    this.platformType,
  });
  final String status;
  final String message;
  final String? deviceToken;
  final PlatformType? platformType;

  @override
  String toString() => jsonEncode(_$RegisterDeviceResponseToJson(this));
}
