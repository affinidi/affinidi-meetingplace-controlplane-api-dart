import 'dart:io';

import 'package:shelf/shelf.dart';

import '../../core/service/group/group_service.dart';
import '../../server/utils.dart';
import '../application_facade.dart';
import '../request_validation_exception.dart';
import 'request_model.dart';
import 'response_error_model.dart';
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
  } on GroupDeleted catch (e) {
    facade.logInfo('Group has been deleted with id ${e.groupId}');
    return Response(
      HttpStatus.gone,
      body: GroupNotifyChannelErrorResponse.deleted().toString(),
    );
  } on GroupNotFound catch (e) {
    facade.logInfo('Group doesnt exist with id ${e.groupId}');
    return Response.notFound(
      GroupNotifyChannelErrorResponse.notFound().toString(),
    );
  } on GroupMemberNotInGroup catch (e) {
    facade.logInfo('Group member not in group ${e.groupId}');
    return Response.forbidden(
      GroupNotifyChannelErrorResponse.notInGroup().toString(),
    );
  } catch (e, stackTrace) {
    facade.logError(
      'Error on group notify channel',
      error: e,
      stackTrace: stackTrace,
    );
    return Response.internalServerError();
  }
}
