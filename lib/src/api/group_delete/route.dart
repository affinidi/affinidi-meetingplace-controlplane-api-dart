import 'dart:io';

import '../../core/service/group/group_service.dart';
import '../request_validation_exception.dart';
import 'request_model.dart';
import 'response_error_model.dart';
import '../../server/utils.dart';
import '../application_facade.dart';
import 'package:shelf/shelf.dart';

import 'response_model.dart';

Future<Response> groupDelete(Request request, ApplicationFacade facade) async {
  try {
    final groupDeleteRequest = GroupDeleteRequest.fromRequestParams(
      await request.readAsString(),
    );

    await facade.deleteGroup(groupDeleteRequest, getAuthDid(request));
    return Response.ok(
      GroupDeleteResponse(
        status: 'success',
        message: 'Group deleted successfully',
      ).toString(),
    );
  } on RequestValidationException catch (e) {
    return Response.badRequest(body: e.toString());
  } on GroupDeleted catch (e) {
    facade.logInfo('Group with id has been deleted: ${e.groupId}');
    return Response(
      HttpStatus.gone,
      body: GroupDeleteErrorResponse.groupDeleted().toString(),
    );
  } on GroupNotFound catch (e) {
    facade.logInfo('Group with id does not exist: ${e.groupId}');
    return Response.notFound(
      GroupDeleteErrorResponse.groupDoesNotExist().toString(),
    );
  } on GroupPermissionDenied {
    facade.logInfo('Request did not allowed to delete group');
    return Response.forbidden(
      GroupDeleteErrorResponse.groupPermissionDenied().toString(),
    );
  } catch (e, stackTrace) {
    facade.logError('Error on group delete', error: e, stackTrace: stackTrace);
    return Response.internalServerError();
  }
}
