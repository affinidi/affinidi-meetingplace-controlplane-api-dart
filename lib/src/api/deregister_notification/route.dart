import '../../core/service/notification/notification_service.dart';
import '../application_facade.dart';
import '../request_validation_exception.dart';
import 'request_model.dart';
import 'response_error_model.dart';
import 'response_model.dart';
import '../../server/utils.dart';
import 'package:shelf/shelf.dart';

Future<Response> deregisterNotification(
  Request request,
  ApplicationFacade facade,
) async {
  try {
    final deregisterNotificationRequest =
        DeregisterNotificationRequest.fromRequestParams(
          await request.readAsString(),
        );

    await facade.deregisterNotification(
      deregisterNotificationRequest,
      getAuthDid(request),
    );

    return Response.ok(
      DeregisterNotificationResponse(status: 'success').toString(),
    );
  } on RequestValidationException catch (e) {
    return Response.badRequest(body: e.toString());
  } on NotAuthorizedException {
    facade.logInfo(
      'Requester is not authorized to deregister notification token',
    );
    return Response.forbidden(
      DeregisterNotificationErrorResponse.permissionDenied().toString(),
    );
  } on NotificationChannelNotFound {
    facade.logInfo('Notification channel not found');
    return Response.notFound(
      DeregisterNotificationErrorResponse.notFound().toString(),
    );
  } catch (e, stackTrace) {
    facade.logError(
      'Error deregistering notification: $e',
      error: e,
      stackTrace: stackTrace,
    );
    return Response.internalServerError();
  }
}
