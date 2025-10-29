import 'package:shelf/shelf.dart';
import '../request_validation_exception.dart';
import 'request_model.dart';
import 'response_model.dart';
import '../application_facade.dart';

Future<Response> checkOfferPhrase(
  Request request,
  ApplicationFacade facade,
) async {
  try {
    final checkOfferPhraseRequest =
        CheckOfferPhraseRequest.fromRequestParams(await request.readAsString());

    final isInUse = await facade.checkOfferPhrase(checkOfferPhraseRequest);
    return Response.ok(CheckOfferPhraseResponse(isInUse: isInUse).toString());
  } on RequestValidationException catch (e) {
    return Response.badRequest(body: e.toString());
  } catch (e, stackTrace) {
    facade.logError('Error on check offer phrase',
        error: e, stackTrace: stackTrace);
    return Response.internalServerError();
  }
}
