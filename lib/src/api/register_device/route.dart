import '../request_validation_exception.dart';
import 'request_model.dart';
import 'response_model.dart';
import '../../server/utils.dart';
import '../application_facade.dart';
import 'package:shelf/shelf.dart';

Future<Response> registerDevice(
  Request request,
  ApplicationFacade facade,
) async {
  try {
    final registerDeviceRequest = RegisterDeviceRequest.fromRequestParams(
      await request.readAsString(),
    );

    final result = await facade.registerDevice(
      registerDeviceRequest,
      getAuthDid(request),
    );

    return Response.ok(
      RegisterDeviceResponse.success(
        deviceToken: result.deviceToken,
        platformType: result.platformType,
      ).toString(),
    );
  } on RequestValidationException catch (e) {
    return Response.badRequest(body: e.toString());
  } catch (e, stackTrace) {
    facade.logError(
      'Error on register device',
      error: e,
      stackTrace: stackTrace,
    );
    return Response.internalServerError(
      body: RegisterDeviceResponse.error().toString(),
    );
  }
}
