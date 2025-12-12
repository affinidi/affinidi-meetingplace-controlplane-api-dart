import '../request_validation_exception.dart';
import 'request_model.dart';
import '../../server/utils.dart';
import '../application_facade.dart';
import 'package:shelf/shelf.dart';

import 'response_model.dart';

Future<Response> groupSendMessage(
  Request request,
  ApplicationFacade facade,
) async {
  try {
    final groupSendMessageRequest = GroupSendMessage.fromRequestParams(
      await request.readAsString(),
    );

    await facade.sendGroupMessage(groupSendMessageRequest, getAuthDid(request));

    return Response.ok(
      GroupSendMessageResponse(
        status: 'success',
        message: 'Group message sent successfully',
      ).toString(),
    );
  } on RequestValidationException catch (e) {
    return Response.badRequest(body: e.toString());
  } catch (e, stackTrace) {
    facade.logError(
      'Error on group send message',
      error: e,
      stackTrace: stackTrace,
    );
    return Response.internalServerError();
  }
}
