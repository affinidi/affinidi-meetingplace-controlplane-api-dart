import '../request_validation_exception.dart';
import 'request_model.dart';
import 'response_model.dart';
import '../../server/utils.dart';
import '../application_facade.dart';
import 'package:shelf/shelf.dart';

Future<Response> registerNotification(
  Request request,
  ApplicationFacade facade,
) async {
  try {
    final registerNotificationRequest =
        RegisterNotificationRequest.fromRequestParams(
          await request.readAsString(),
        );

    final notificationChannel = await facade.registerNotification(
      registerNotificationRequest,
      getAuthDid(request),
    );

    return Response.ok(
      RegisterNotificationResponse.fromNotificationChannel(
        notificationChannel,
      ).toString(),
    );
  } on RequestValidationException catch (e) {
    return Response.badRequest(body: e.toString());
  } catch (e, stackTrace) {
    facade.logError(
      'Register notification failed: $e',
      error: e,
      stackTrace: stackTrace,
    );
    return Response.internalServerError();
  }
}
