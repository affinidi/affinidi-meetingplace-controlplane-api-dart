import 'dart:io';

import '../../request_validation_exception.dart';
import 'request_model.dart';
import 'response_error_model.dart';
import 'response_model.dart';
import '../../../server/utils.dart';
import '../../application_facade.dart';
import '../../../core/service/offer/offer_service.dart';
import 'package:shelf/shelf.dart';

Future<Response> adminDeregisterOffer(
  Request request,
  ApplicationFacade facade,
) async {
  try {
    final deregisterOfferRequest =
        AdminDeregisterOfferRequest.fromRequestParams(
          await request.readAsString(),
        );

    await facade.deregisterOfferAsAdmin(
      deregisterOfferRequest,
      getAuthDid(request),
    );

    return Response.ok(AdminDeregisterOfferResponse.success().toString());
  } on RequestValidationException catch (e) {
    return Response.badRequest(body: e.toString());
  } on OfferNotFound {
    return Response(
      HttpStatus.conflict,
      body: AdminDeregisterOfferErrorResponse.notFound().toString(),
    );
  } on NotAuthorizedException {
    return Response.forbidden(
      AdminDeregisterOfferErrorResponse.permissionDenied().toString(),
    );
  } catch (e, stackTrace) {
    facade.logError(
      'Admin deregister offer action failed: $e',
      error: e,
      stackTrace: stackTrace,
    );
    return Response.internalServerError();
  }
}
