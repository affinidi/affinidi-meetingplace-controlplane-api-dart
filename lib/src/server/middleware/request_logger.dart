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
      final responseBody = await response.readAsString();

      logger.info('=== Response ===');
      logger.info('Status code ${response.statusCode}');
      logger.debug(jsonEncode(responseBody));
      logger.info('=== Response end ===');

      return Response(
        response.statusCode,
        body: responseBody,
        headers: response.headers,
      );
    };
  };
}
