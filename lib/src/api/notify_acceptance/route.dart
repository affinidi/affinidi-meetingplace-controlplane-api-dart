import '../request_validation_exception.dart';
import 'request_model.dart';
import 'response_error_model.dart';
import '../../server/utils.dart';
import '../application_facade.dart';
import '../../core/service/acceptance/acceptance_service.dart';
import '../../core/service/offer/offer_service.dart';
import 'package:shelf/shelf.dart';

Future<Response> notifyAcceptance(
  Request request,
  ApplicationFacade facade,
) async {
  try {
    final notifyAcceptanceRequest = NotifyAcceptanceRequest.fromRequestParams(
      await request.readAsString(),
    );

    await facade.notifyAcceptance(
      notifyAcceptanceRequest,
      getAuthDid(request),
    );

    return Response.ok('');
  } on RequestValidationException catch (e) {
    return Response.badRequest(body: e.toString());
  } on OfferNotFound {
    return Response.badRequest(
      body: NotifyAcceptanceErrorResponse.offerNotFound().toString(),
    );
  } on AcceptanceNotFound {
    return Response.badRequest(
      body: NotifyAcceptanceErrorResponse.acceptanceNotFound().toString(),
    );
  } catch (e, stackTrace) {
    facade.logError('Error on notify acceptance: $e',
        error: e, stackTrace: stackTrace);
    return Response.internalServerError();
  }
}
