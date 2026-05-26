import '../request_validation_exception.dart';
import 'request_model.dart';
import '../../server/utils.dart';
import '../application_facade.dart';
import 'package:shelf/shelf.dart';

import 'response_model.dart';

Future<Response> groupNotifyChannel(
  Request request,
  ApplicationFacade facade,
) async {
  try {
    final groupNotifyChannelRequest = GroupNotifyChannel.fromRequestParams(
      await request.readAsString(),
    );

    await facade.notifyGroupChannel(
      groupNotifyChannelRequest,
      getAuthDid(request),
    );

    return Response.ok(
      GroupNotifyChannelResponse(
        status: 'success',
        message: 'Group channel notified successfully',
      ).toString(),
    );
  } on RequestValidationException catch (e) {
    return Response.badRequest(body: e.toString());
  } catch (e, stackTrace) {
    facade.logError(
      'Error on group notify channel',
      error: e,
      stackTrace: stackTrace,
    );
    return Response.internalServerError();
  }
}
