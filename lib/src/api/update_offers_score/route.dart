import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';

import '../../core/service/offer/offer_service.dart';
import '../application_facade.dart';
import '../request_validation_exception.dart';
import 'request_model.dart';
import 'response_error_model.dart';
import 'response_model.dart';

Future<Response> updateOffersScore(
  Request request,
  ApplicationFacade facade,
) async {
  try {
    final requestBody = await request.readAsString();
    final input = UpdateOffersScoreRequest.fromRequestParams(requestBody);

    final authDid = request.context['authDid'] as String;

    final updatedOffers = await facade.updateOffersScore(
      input.score,
      input.mnemonics,
      authDid,
    );

    return Response.ok(
      jsonEncode(UpdateOffersScoreResponse(updatedOffers: updatedOffers)),
      headers: {'content-type': 'application/json'},
    );
  } on RequestValidationException catch (e) {
    return Response.badRequest(
      body: UpdateOffersScoreErrorResponse.validationFailed(
        e.toString(),
      ).toString(),
    );
  } on OfferNotFound {
    return Response(
      HttpStatus.conflict,
      body: UpdateOffersScoreErrorResponse.notFound().toString(),
    );
  } on NotAuthorizedException {
    return Response.forbidden(
      UpdateOffersScoreErrorResponse.permissionDenied().toString(),
    );
  } catch (e, stackTrace) {
    facade.logError(
      'Error updating score: $e',
      error: e,
      stackTrace: stackTrace,
    );
    return Response.internalServerError();
  }
}
