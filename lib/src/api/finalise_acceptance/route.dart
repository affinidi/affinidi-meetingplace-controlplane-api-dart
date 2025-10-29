import '../request_validation_exception.dart';
import 'request_model.dart';
import 'response_model.dart';
import '../../server/utils.dart';
import '../application_facade.dart';
import 'package:shelf/shelf.dart';

Future<Response> finaliseAcceptance(
  Request request,
  ApplicationFacade facade,
) async {
  try {
    final finaliseAcceptanceRequest =
        FinaliseAcceptanceRequest.fromRequestParams(
      await request.readAsString(),
    );

    final String? notificationToken = await facade.finaliseAcceptance(
      finaliseAcceptanceRequest,
      getAuthDid(request),
    );

    return Response.ok(
      FinaliseAcceptanceResponse(
        notificationToken: notificationToken,
      ).toString(),
    );
  } on RequestValidationException catch (e) {
    return Response.badRequest(body: e.toString());
  } catch (e, stackTrace) {
    facade.logError('Finalise acceptance failed: $e',
        error: e, stackTrace: stackTrace);
    return Response.internalServerError();
  }
}
