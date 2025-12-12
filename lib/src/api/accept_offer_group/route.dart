import '../accept_offer/response_error_model.dart';
import '../request_validation_exception.dart';
import 'request_model.dart';
import 'response_model.dart';
import '../../core/service/offer/offer_service.dart';
import '../../server/utils.dart';
import '../application_facade.dart';
import 'package:shelf/shelf.dart';

Future<Response> acceptOfferGroup(
  Request request,
  ApplicationFacade facade,
) async {
  try {
    final acceptOfferGroupRequest = AcceptOfferGroupRequest.fromRequestParams(
      await request.readAsString(),
    );

    final offer = await facade.acceptOfferGroup(
      acceptOfferGroupRequest,
      getAuthDid(request),
    );

    return Response.ok(AcceptOfferGroupResponse.fromOffer(offer).toString());
  } on RequestValidationException catch (e) {
    return Response.badRequest(body: e.toString());
  } on OfferNotFound catch (e) {
    facade.logInfo('Offer not found for mnemonic: ${e.mnemonic}');
    return Response.notFound(
      AcceptOfferErrorResponse.offerNotFound().toString(),
    );
  } on OfferExpired catch (e) {
    facade.logInfo('Invalid offer with mnemonic: ${e.mnemonic}');
    return Response.badRequest(
      body: AcceptOfferErrorResponse.offerInvalid().toString(),
    );
  } catch (e, stackTrace) {
    facade.logError(
      'Error on accept offer group',
      error: e,
      stackTrace: stackTrace,
    );
    return Response.internalServerError();
  }
}
