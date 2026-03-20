import 'dart:io';

import '../../core/service/group/group_service.dart';
import '../request_validation_exception.dart';
import 'request_model.dart';
import 'response_error_model.dart';
import 'response_model.dart';
import '../../server/utils.dart';
import '../application_facade.dart';
import 'package:shelf/shelf.dart';

Future<Response> notifyChannelGroup(
  Request request,
  ApplicationFacade facade,
) async {
  try {
    final notifyChannelGroupRequest =
        NotifyChannelGroupRequest.fromRequestParams(
          await request.readAsString(),
        );

    final notifiedCount = await facade.notifyAllGroupMembers(
      notifyChannelGroupRequest,
      getAuthDid(request),
    );

    return Response.ok(
      NotifyChannelGroupResponse(notifiedCount: notifiedCount).toString(),
    );
  } on RequestValidationException catch (e) {
    return Response.badRequest(body: e.toString());
  } on GroupNotFound {
    return Response.notFound(
      NotifyChannelGroupErrorResponse.groupNotFound().toString(),
    );
  } on GroupDeleted {
    return Response(
      HttpStatus.gone,
      body: NotifyChannelGroupErrorResponse.groupDeleted().toString(),
    );
  } on GroupMemberNotInGroup {
    return Response.forbidden(
      NotifyChannelGroupErrorResponse.notInGroup().toString(),
    );
  } catch (e, stackTrace) {
    facade.logError(
      'Error on notify channel group: $e',
      error: e,
      stackTrace: stackTrace,
    );
    return Response.internalServerError();
  }
}
