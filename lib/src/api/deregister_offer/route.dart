import 'dart:io';

import '../request_validation_exception.dart';
import 'request_model.dart';
import 'response_error_model.dart';
import 'response_model.dart';
import '../../server/utils.dart';
import '../application_facade.dart';
import '../../core/service/offer/offer_service.dart';
import 'package:shelf/shelf.dart';

Future<Response> deregisterOffer(
  Request request,
  ApplicationFacade facade,
) async {
  try {
    final deregisterOfferRequest = DeregisterOfferRequest.fromRequestParams(
      await request.readAsString(),
    );

    await facade.deregisterOffer(deregisterOfferRequest, getAuthDid(request));

    return Response.ok(DeregisterOfferResponse.success().toString());
  } on RequestValidationException catch (e) {
    return Response.badRequest(body: e.toString());
  } on OfferNotFound {
    return Response(
      HttpStatus.conflict,
      body: DeregisterOfferErrorResponse.notFound().toString(),
    );
  } on OfferLinkMismatch {
    return Response(
      HttpStatus.badRequest,
      body: DeregisterOfferErrorResponse.offerLinkMismatch().toString(),
    );
  } on NotAuthorizedException {
    return Response.forbidden(
      DeregisterOfferErrorResponse.permissionDenied().toString(),
    );
  } catch (e, stackTrace) {
    facade.logError(
      'Deregister offer action failed: $e',
      error: e,
      stackTrace: stackTrace,
    );
    return Response.internalServerError();
  }
}
