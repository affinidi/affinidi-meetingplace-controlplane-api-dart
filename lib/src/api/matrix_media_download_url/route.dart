import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../../core/service/matrix/matrix_media_access_service.dart';
import '../application_facade.dart';

Future<Response> matrixMediaDownloadUrl(
  Request request,
  ApplicationFacade facade,
) async {
  try {
    final bodyText = await request.readAsString();
    final dynamic decoded = bodyText.trim().isEmpty
        ? <String, dynamic>{}
        : jsonDecode(bodyText);

    if (decoded is! Map<String, dynamic>) {
      return Response.badRequest(
        body: jsonEncode({'error': 'Request body must be a JSON object'}),
      );
    }

    final challengeResponse = (decoded['challenge_response'] as String?)
        ?.trim();
    final homeserverValue = (decoded['homeserver'] as String?)?.trim();
    final roomId = (decoded['room_id'] as String?)?.trim();
    final mediaUri = (decoded['media_uri'] as String?)?.trim();

    if (challengeResponse == null || challengeResponse.isEmpty) {
      return Response.badRequest(
        body: jsonEncode({'error': 'challenge_response is required'}),
      );
    }

    if (homeserverValue == null || homeserverValue.isEmpty) {
      return Response.badRequest(
        body: jsonEncode({'error': 'homeserver is required'}),
      );
    }

    if (roomId == null || roomId.isEmpty) {
      return Response.badRequest(
        body: jsonEncode({'error': 'room_id is required'}),
      );
    }

    if (mediaUri == null || mediaUri.isEmpty) {
      return Response.badRequest(
        body: jsonEncode({'error': 'media_uri is required'}),
      );
    }

    final authDid = await facade.authenticateDidFromChallengeResponse(
      challengeResponse,
    );
    final url = await facade.createMatrixMediaDownloadUrl(
      authDid: authDid,
      homeserver: Uri.parse(homeserverValue),
      roomId: roomId,
      mxcUri: mediaUri,
    );

    return Response.ok(
      jsonEncode({'url': url}),
      headers: {'content-type': 'application/json'},
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
