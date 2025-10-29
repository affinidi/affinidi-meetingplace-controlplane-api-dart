import '../application_facade.dart';
import '../request_validation_exception.dart';
import 'request_model.dart';
import 'response_error_model.dart';
import 'response_model.dart';
import '../../server/utils.dart';
import '../../core/service/offer/offer_service.dart';
import 'package:shelf/shelf.dart';

Future<Response> queryOffer(Request request, ApplicationFacade facade) async {
  try {
    final queryOfferRequest = QueryOfferRequest.fromRequestParams(
      await request.readAsString(),
    );

    final offer = await facade.queryOffer(
      queryOfferRequest,
      getAuthDid(request),
    );

    if (offer == null) {
      return Response.notFound(QueryOfferErrorResponse.notFound().toString());
    }

    return Response.ok(QueryOfferResponse.fromOffer(offer).toString());
  } on RequestValidationException catch (e) {
    return Response.badRequest(body: e.toString());
  } on OfferQueryLimitExceeded {
    return Response.badRequest(
      body: QueryOfferErrorResponse.limitExceeded().toString(),
    );
  } catch (e, stackTrace) {
    facade.logError('Query offer failed: $e', error: e, stackTrace: stackTrace);
    return Response.internalServerError();
  }
}
