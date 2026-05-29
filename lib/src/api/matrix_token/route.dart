import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../application_facade.dart';
import '../request_validation_exception.dart';
import 'request_model.dart';

Future<Response> matrixToken(Request request, ApplicationFacade facade) async {
  try {
    final bodyText = await request.readAsString();
    final params = MatrixTokenRequest.fromRequestParams(bodyText);

    final authDid = await facade.authenticateDidFromChallengeResponse(
      params.challengeResponse,
    );
    final token = await facade.issueMatrixLoginToken(
      authDid: authDid,
      homeserver: Uri.parse(params.homeserver),
    );

    return Response.ok(
      jsonEncode({'token': token}),
      headers: {'content-type': 'application/json'},
    );
  } on RequestValidationException catch (e) {
    return Response.badRequest(body: e.toString());
  } on FormatException catch (e) {
    return Response.badRequest(body: jsonEncode({'error': e.message}));
  } catch (e, stackTrace) {
    facade.logError(
      'Error issuing Matrix token',
      error: e,
      stackTrace: stackTrace,
    );
    return Response.internalServerError(
      body: jsonEncode({'error': 'Unable to issue Matrix token'}),
    );
  }
}
