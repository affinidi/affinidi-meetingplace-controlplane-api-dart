import '../request_validation_exception.dart';
import 'request_model.dart';
import 'response_error_model.dart';
import 'response_model.dart';
import '../../server/utils.dart';
import '../application_facade.dart';
import '../../core/service/notification/notification_service.dart';
import 'package:shelf/shelf.dart';

Future<Response> notifyChannel(
  Request request,
  ApplicationFacade facade,
) async {
  try {
    final notifyChannelRequest = NotifyChannelRequest.fromRequestParams(
      await request.readAsString(),
    );

    final notificationItem = await facade.notifyChannel(
      notifyChannelRequest,
      getAuthDid(request),
    );

    return Response.ok(
      NotifyChannelResponse.fromNotificationItem(notificationItem).toString(),
    );
  } on RequestValidationException catch (e) {
    return Response.badRequest(body: e.toString());
  } on NotificationChannelNotFound {
    return Response.badRequest(
      body: NotifyChannelErrorResponse.notificationChannelNotFound().toString(),
    );
  } catch (e, stackTrace) {
    facade.logError('Error on notifying channel: $e',
        error: e, stackTrace: stackTrace);
    return Response.internalServerError();
  }
}
