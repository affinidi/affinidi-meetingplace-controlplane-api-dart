import 'dart:io';

import '../request_validation_exception.dart';
import 'request_model.dart';
import 'response_error_model.dart';
import 'response_model.dart';
import '../../server/utils.dart';
import '../application_facade.dart';
import '../../core/service/offer/offer_service.dart';
import 'package:shelf/shelf.dart';

Future<Response> registerOfferGroup(
  Request request,
  ApplicationFacade facade,
) async {
  try {
    final registerOfferGroupRequest =
        RegisterOfferGroupRequest.fromRequestParams(
      await request.readAsString(),
    );

    final (offer, group) = await facade.registerOfferGroup(
      registerOfferGroupRequest,
      getAuthDid(request),
    );

    return Response.ok(
      RegisterOfferGroupResponse.fromOfferAndGroup(offer, group).toString(),
    );
  } on RequestValidationException catch (e) {
    return Response.badRequest(body: e.toString());
  } on InvalidOfferInput catch (e) {
    return Response.badRequest(
      body: RegisterOfferGroupErrorResponse.invalidInput(e.message).toString(),
    );
  } on OfferExists {
    return Response(
      HttpStatus.conflict,
      body: RegisterOfferGroupResponse.offerExists().toString(),
    );
  } on GroupCountLimitExceeded {
    return Response.badRequest(
      body:
          RegisterOfferGroupErrorResponse.groupCountLimitExceeded().toString(),
    );
  } catch (e, stackTrace) {
    facade.logError('Internal server error: $e',
        error: e, stackTrace: stackTrace);
    return Response.internalServerError();
  }
}
