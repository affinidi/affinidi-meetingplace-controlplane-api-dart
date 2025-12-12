import 'dart:io';

import '../../core/service/group/group_service.dart';
import '../request_validation_exception.dart';
import 'request_model.dart';
import 'response_error_model.dart';
import '../../server/utils.dart';
import '../application_facade.dart';
import 'package:shelf/shelf.dart';

import 'response_model.dart';

Future<Response> groupAddMember(
  Request request,
  ApplicationFacade facade,
) async {
  try {
    final groupAddMemberRequest = GroupAddMemberRequest.fromRequestParams(
      await request.readAsString(),
    );

    await facade.addMemberToGroup(groupAddMemberRequest, getAuthDid(request));
    return Response.ok(
      GroupAddMemberResponse(
        status: 'success',
        message: 'Group member added successfully',
      ).toString(),
    );
  } on RequestValidationException catch (e) {
    return Response.badRequest(body: e.toString());
  } on GroupPermissionDenied {
    facade.logInfo(
      '''Access to group denied. Only group owner is allowed to call this action''',
    );
    return Response.forbidden(
      GroupAddMemberErrorResponse.permissionDenied().toString(),
    );
  } on GroupDeleted catch (e) {
    facade.logInfo('Group with id has been deleted: ${e.groupId}');
    return Response(
      HttpStatus.gone,
      body: GroupAddMemberErrorResponse.groupDeleted().toString(),
    );
  } on GroupNotFound catch (e) {
    facade.logInfo('Group with id does not exist: ${e.groupId}');
    return Response.notFound(
      GroupAddMemberErrorResponse.groupDoesNotExist().toString(),
    );
  } catch (e, stackTrace) {
    facade.logError(
      'Error on group add member',
      error: e,
      stackTrace: stackTrace,
    );
    return Response.internalServerError();
  }
}
