import 'dart:io';

import '../../core/service/group/group_service.dart';
import '../request_validation_exception.dart';
import 'request_model.dart';
import '../../server/utils.dart';
import '../application_facade.dart';
import 'package:shelf/shelf.dart';

import 'response_error_model.dart';
import 'response_model.dart';

Future<Response> groupDeregisterMember(
  Request request,
  ApplicationFacade facade,
) async {
  try {
    final groupMemberDeregisterRequest =
        GroupMemberDeregisterRequest.fromRequestParams(
          await request.readAsString(),
        );

    await facade.deregisterMemberFromGroup(
      groupMemberDeregisterRequest,
      getAuthDid(request),
    );

    return Response.ok(
      GroupMemberDeregisterReponse(
        status: 'success',
        message: 'Group member deregistered successfully',
      ).toString(),
    );
  } on RequestValidationException catch (e) {
    return Response.badRequest(body: e.toString());
  } on GroupDeleted catch (e) {
    facade.logInfo('Group has been deleted with id ${e.groupId}');
    return Response(
      HttpStatus.gone,
      body: GroupMemberDeregisterErrorResponse.deleted().toString(),
    );
  } on GroupNotFound catch (e) {
    facade.logInfo('Group doesnt exist with id ${e.groupId}');
    return Response.notFound(
      GroupMemberDeregisterErrorResponse.notFound().toString(),
    );
  } on GroupMemberNotInGroup catch (e) {
    facade.logInfo('Group member not in group ${e.groupId}');
    return Response.forbidden(
      GroupMemberDeregisterErrorResponse.notInGroup().toString(),
    );
  } catch (e, stackTrace) {
    facade.logError(
      'Error on group member deregister',
      error: e,
      stackTrace: stackTrace,
    );
    return Response.internalServerError();
  }
}
