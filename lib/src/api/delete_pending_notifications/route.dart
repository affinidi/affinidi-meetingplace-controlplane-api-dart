import '../application_facade.dart';
import '../request_validation_exception.dart';
import 'request_model.dart';
import 'response_model.dart';
import 'package:shelf/shelf.dart';

Future<Response> deletePendingNotifications(
  Request request,
  ApplicationFacade facade,
) async {
  try {
    final deletePendingNotificationsRequest =
        DeletePendingNotificationsRequest.fromRequestParams(
          await request.readAsString(),
        );

    final result = await facade.deletePendingNotifications(
      deletePendingNotificationsRequest,
    );

    return Response.ok(
      DeletePendingNotificationsResponse(
        deletedIds: result['deletedNotificationIds'],
        notifications: result['remainingNotifications']
            .map((notification) {
              return NotificationResponse(
                id: notification.getId(),
                offerLink: notification.offerLink,
                deviceHash: notification.deviceHash,
                did: notification.consumerAuthDid,
                payload: notification.payload,
              );
            })
            .toList()
            .cast<NotificationResponse>(),
      ).toString(),
    );
  } on RequestValidationException catch (e) {
    return Response.badRequest(body: e.toString());
  } catch (e, stackTrace) {
    facade.logError(
      'Error deleting pending notifications: $e',
      error: e,
      stackTrace: stackTrace,
    );
    return Response.internalServerError();
  }
}
