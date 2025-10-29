import '../request_validation_exception.dart';
import 'request_model.dart';
import 'response_model.dart';
import '../application_facade.dart';
import 'package:shelf/shelf.dart';

Future<Response> getPendingNotifications(
  Request request,
  ApplicationFacade facade,
) async {
  try {
    final getPendingNotificationsRequest =
        GetPendingNotificationsRequest.fromRequestParams(
      await request.readAsString(),
    );

    final pendingNotifications =
        await facade.getPendingNotifications(getPendingNotificationsRequest);

    facade.logInfo('Found ${pendingNotifications.length} notifications');
    return Response.ok(
      GetPendingNotificationsResponse.fromPendingNotifications(
        pendingNotifications,
      ).toString(),
    );
  } on RequestValidationException catch (e) {
    return Response.badRequest(body: e.toString());
  } catch (e, stackTrace) {
    facade.logError('Error while getting pending notifications: $e',
        error: e, stackTrace: stackTrace);
    return Response.internalServerError();
  }
}
