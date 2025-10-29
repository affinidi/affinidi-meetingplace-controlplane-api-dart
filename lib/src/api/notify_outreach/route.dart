import '../../core/service/offer/offer_service.dart';
import '../request_validation_exception.dart';
import 'request_model.dart';
import '../../server/utils.dart';
import '../application_facade.dart';
import 'package:shelf/shelf.dart';

import 'response_error_model.dart';
import 'response_model.dart';

Future<Response> notifyOutreach(
  Request request,
  ApplicationFacade facade,
) async {
  try {
    final notifyOutreachRequest = NotifyOutreachRequest.fromRequestParams(
      await request.readAsString(),
    );

    await facade.notifyOutreach(
      notifyOutreachRequest,
      getAuthDid(request),
    );

    return Response.ok(NotifyOutreachResponse(
      message: 'Notify outreach successful',
      status: 'success',
    ).toString());
  } on RequestValidationException catch (e) {
    return Response.badRequest(body: e.toString());
  } on OfferNotFound {
    return Response.badRequest(
      body: NotifyOutreachErrorResponse.offerNotFound().toString(),
    );
  } catch (e, stackTrace) {
    facade.logError('Error on notify outreach: $e',
        error: e, stackTrace: stackTrace);
    return Response.internalServerError();
  }
}
