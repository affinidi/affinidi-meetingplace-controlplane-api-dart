import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../../core/service/matrix/matrix_media_access_service.dart';
import '../application_facade.dart';
import '../request_validation_exception.dart';
import 'request_model.dart';

Future<Response> matrixMediaDownloadUrl(
  Request request,
  ApplicationFacade facade,
) async {
  try {
    final bodyText = await request.readAsString();
    final params = MatrixMediaDownloadUrlRequest.fromRequestParams(bodyText);

    final authDid = await facade.authenticateDidFromChallengeResponse(
      params.challengeResponse,
    );
    final url = await facade.createMatrixMediaDownloadUrl(
      authDid: authDid,
      homeserver: Uri.parse(params.homeserver),
      roomId: params.roomId,
      mxcUri: params.mediaUri,
    );

    return Response.ok(
      jsonEncode({'url': url}),
      headers: {'content-type': 'application/json'},
    );
  } on RequestValidationException catch (e) {
    return Response.badRequest(body: e.toString());
  } on TypeError {
    return Response.badRequest(
      body: jsonEncode({'error': 'Missing or invalid required fields'}),
    );
  } on FormatException catch (e) {
    return Response.badRequest(body: jsonEncode({'error': e.message}));
  } on MatrixMediaAccessException catch (e) {
    return Response(e.statusCode, body: jsonEncode({'error': e.message}));
  } catch (e, stackTrace) {
    facade.logError(
      'Error creating Matrix media download URL',
      error: e,
      stackTrace: stackTrace,
    );
    return Response.internalServerError(
      body: jsonEncode({'error': 'Unable to create Matrix media download URL'}),
    );
  }
}
