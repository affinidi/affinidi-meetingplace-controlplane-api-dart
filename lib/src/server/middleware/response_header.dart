import 'dart:io';
import 'package:shelf/shelf.dart';

Middleware defaultContentType(String contentType) {
  return (Handler innerHandler) {
    return (Request request) async {
      final response = await innerHandler(request);
      if (!response.headers.containsKey(HttpHeaders.contentTypeHeader)) {
        return response.change(headers: {
          HttpHeaders.contentTypeHeader: contentType,
          ...response.headers,
        });
      }
      return response;
    };
  };
}
