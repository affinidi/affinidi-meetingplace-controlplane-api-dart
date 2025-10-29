import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

getShelfRequest({
  required String method,
  required String path,
  required Object request,
}) {
  return Request(
    method,
    Uri.parse('http://localhost:3000/$path'),
    body: JsonEncoder().convert(request),
  );
}

Future<NormalizedResponse> getResponse(Future<Response> fn) async {
  Response response = await fn;
  return NormalizedResponse(
    statusCode: response.statusCode,
    body: await response.readAsString(),
  );
}

expectInternalServerResponse(Future<Response> fn) async {
  Response response = await fn;
  expect(response.statusCode, 500);
  expect(await response.readAsString(), 'Internal Server Error');
}

class NormalizedResponse {
  NormalizedResponse({required this.statusCode, required this.body});
  final int statusCode;
  final Object body;
}
