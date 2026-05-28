import 'dart:convert';

import '../../core/logger/logger.dart';
import 'package:shelf/shelf.dart';

Middleware requestLoggerMiddleware(Logger logger) {
  return (Handler innerHandler) {
    return (Request request) async {
      logger.info('${request.method} ${request.requestedUri}');
      final body = await request.readAsString();
      logger.debug('Body: $body');

      // Recreate the request with the body so it can be read again
      final newRequest = request.change(body: body);

      final response = await innerHandler(newRequest);

      final contentType = response.headers['content-type'] ?? '';
      final isTextual =
          contentType.contains('json') || contentType.contains('text');

      logger.info('=== Response ===');
      logger.info('Status code ${response.statusCode}');

      if (isTextual) {
        final responseBody = await response.readAsString();
        logger.debug(jsonEncode(responseBody));
        logger.info('=== Response end ===');

        return Response(
          response.statusCode,
          body: responseBody,
          headers: response.headers,
        );
      } else {
        final responseBytes = await response.read().expand((c) => c).toList();
        logger.debug('[binary ${responseBytes.length} bytes]');
        logger.info('=== Response end ===');

        return Response(
          response.statusCode,
          body: responseBytes,
          headers: response.headers,
        );
      }
    };
  };
}
