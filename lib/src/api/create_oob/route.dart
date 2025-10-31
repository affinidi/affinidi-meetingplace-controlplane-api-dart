import 'package:shelf/shelf.dart';
import '../request_validation_exception.dart';
import 'request_model.dart';
import 'response_model.dart';
import '../application_facade.dart';
import '../../core/config/config.dart';
import '../../core/config/env_config.dart';

Future<Response> createOob(Request request, ApplicationFacade facade) async {
  try {
    final createOobRequest = CreateOobRequest.fromRequestParams(
      await request.readAsString(),
    );

    final oob = await facade.createOob(createOobRequest);
    final url = '${getEnv('API_ENDPOINT')}${Config().get('oob')['oobUrlPath']}';
    final oobUrl = url.replaceFirst('__OOB_ID__', oob.getId());

    return Response.ok(CreateOobResponse(
      oobId: oob.getId(),
      oobUrl: oobUrl,
    ).toString());
  } on RequestValidationException catch (e) {
    return Response.badRequest(body: e.toString());
  } catch (e, stackTrace) {
    facade.logError('Error on create OOB', error: e, stackTrace: stackTrace);
    return Response.internalServerError();
  }
}
