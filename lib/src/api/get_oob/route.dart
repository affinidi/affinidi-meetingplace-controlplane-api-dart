import '../application_facade.dart';
import '../request_validation_exception.dart';
import 'request_model.dart';
import 'response_model.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Future<Response> getOob(Request request, ApplicationFacade facade) async {
  try {
    if (request.params['id'] == null) return Response.badRequest();
    final getOobRequest = GetOobRequest(oobId: request.params['id']!);

    final oob = await facade.getOob(getOobRequest);

    if (oob == null) {
      return Response.notFound('');
    }

    final ttl = oob.ttl;
    if (ttl != null && ttl.compareTo(DateTime.now().toUtc()).isNegative) {
      return Response.notFound('');
    }

    return Response.ok(GetOobResponse.fromOob(oob).toString());
  } on RequestValidationException catch (e) {
    return Response.badRequest(body: e.toString());
  } catch (e, stackTrace) {
    facade.logError('Error getting OOB: $e', error: e, stackTrace: stackTrace);
    return Response.internalServerError();
  }
}
