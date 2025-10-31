import '../request_validation_exception.dart';
import 'request_model.dart';
import 'response_error_model.dart';
import 'response_model.dart';
import '../../core/service/offer/offer_service.dart';
import '../../server/utils.dart';
import '../application_facade.dart';
import 'package:shelf/shelf.dart';

Future<Response> acceptOffer(Request request, ApplicationFacade facade) async {
  try {
    final acceptOfferRequest = AcceptOfferRequest.fromRequestParams(
      await request.readAsString(),
    );

    final offer = await facade.acceptOffer(
      acceptOfferRequest,
      getAuthDid(request),
    );

    return Response.ok(AcceptOfferResponse.fromOffer(offer).toString());
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
    facade.logError('Accept offer error', error: e, stackTrace: stackTrace);
    return Response.internalServerError();
  }
}
