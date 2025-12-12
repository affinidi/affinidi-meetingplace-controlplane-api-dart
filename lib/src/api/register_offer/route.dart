import 'dart:io';

import '../request_validation_exception.dart';
import 'request_model.dart';
import 'response_error_model.dart';
import 'response_model.dart';
import '../../server/utils.dart';
import '../application_facade.dart';
import '../../core/service/offer/offer_service.dart';
import 'package:shelf/shelf.dart';

Future<Response> registerOffer(
  Request request,
  ApplicationFacade facade,
) async {
  try {
    final registerOfferRequest = RegisterOfferRequest.fromRequestParams(
      await request.readAsString(),
    );

    final offer = await facade.registerOffer(
      registerOfferRequest,
      getAuthDid(request),
    );

    return Response.ok(RegisterOfferResponse.fromOffer(offer).toString());
  } on RequestValidationException catch (e) {
    return Response.badRequest(body: e.toString());
  } on InvalidOfferInput catch (e) {
    return Response.badRequest(
      body: RegisterOfferErrorResponse.invalidInput(e.message).toString(),
    );
  } on OfferExists {
    return Response(
      HttpStatus.conflict,
      body: RegisterOfferResponse.offerExists().toString(),
    );
  } catch (e, stackTrace) {
    facade.logError(
      'Internal server error: $e',
      error: e,
      stackTrace: stackTrace,
    );
    return Response.internalServerError();
  }
}
