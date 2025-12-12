import '../../core/service/device_notification/device_notification_exception.dart';
import '../error_helper.dart';
import '../request_validation_exception.dart';
import 'request_model.dart';
import 'response_error_model.dart';
import '../../server/utils.dart';
import '../application_facade.dart';
import '../../core/service/acceptance/acceptance_service.dart';
import '../../core/service/offer/offer_service.dart';
import 'package:shelf/shelf.dart';

Future<Response> notifyAcceptanceGroup(
  Request request,
  ApplicationFacade facade,
) async {
  try {
    final notifyAcceptanceGroupRequest =
        NotifyAcceptanceGroupRequest.fromRequestParams(
          await request.readAsString(),
        );

    await facade.notifyAcceptanceGroup(
      notifyAcceptanceGroupRequest,
      getAuthDid(request),
    );

    return Response.ok('');
  } on RequestValidationException catch (e) {
    return Response.badRequest(body: e.toString());
  } on OfferNotFound {
    return Response.badRequest(
      body: NotifyAcceptanceGroupErrorResponse.offerNotFound().toString(),
    );
  } on AcceptanceNotFound {
    return Response.badRequest(
      body: NotifyAcceptanceGroupErrorResponse.acceptanceNotFound().toString(),
    );
  } on DeviceNotificationException catch (e, stackTrace) {
    return ErrorHelper.handleDeviceNotificationError(
      error: e,
      stackTrace: stackTrace,
      facade: facade,
      errorResponse: NotifyAcceptanceGroupErrorResponse.notificationError(
        e.message,
      ),
    );
  } catch (e, stackTrace) {
    facade.logError(
      'Error on notify acceptance group: $e',
      error: e,
      stackTrace: stackTrace,
    );
    return Response.internalServerError();
  }
}
