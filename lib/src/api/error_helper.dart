import 'dart:io';

import 'package:shelf/shelf.dart';

import '../../meeting_place_control_plane_api.dart';
import '../core/service/device_notification/device_notification_exception.dart';

class ErrorHelper {
  static handleDeviceNotificationError({
    required DeviceNotificationException error,
    required StackTrace stackTrace,
    required ApplicationFacade facade,
    required Object errorResponse,
  }) {
    facade.logError(
      'Device notification error: ${error.message}',
      error: error,
      stackTrace: stackTrace,
    );

    return Response(HttpStatus.badGateway, body: errorResponse.toString());
  }

  static getMotificationErrorMessage([String? message]) {
    final errorMessage =
        'Unable to send notification: upstream provider returned an error.';

    if (message == null) return errorMessage;
    return '$errorMessage Details: $message';
  }
}
