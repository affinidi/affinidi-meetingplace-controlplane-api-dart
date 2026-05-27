import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';

import '../../core/service/matrix/matrix_media_access_service.dart';
import '../application_facade.dart';

Future<Response> matrixMediaDownload(
  Request request,
  String token,
  ApplicationFacade facade,
) async {
  try {
    final media = await facade.downloadMatrixMedia(token);

    return Response.ok(
      media.bytes,
      headers: {
        HttpHeaders.cacheControlHeader: 'no-store',
        'Content-Disposition': 'attachment',
        'Content-Security-Policy':
            "sandbox; default-src 'none'; script-src 'none';",
        HttpHeaders.contentTypeHeader:
            media.contentType ?? 'application/octet-stream',
      },
    );
  } on MatrixMediaAccessException catch (e) {
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: ContentType.json.mimeType,
    };

    if (e.retryAfterSeconds != null) {
      headers[HttpHeaders.retryAfterHeader] = e.retryAfterSeconds.toString();
    }

    return Response(
      e.statusCode,
      body: jsonEncode({'error': e.message}),
      headers: headers,
    );
  } catch (e, stackTrace) {
    facade.logError(
      'Error downloading Matrix media',
      error: e,
      stackTrace: stackTrace,
    );
    return Response.internalServerError(
      body: jsonEncode({'error': 'Unable to download Matrix media'}),
    );
  }
}
