import 'dart:convert';

import 'package:meeting_place_control_plane_api/src/api/application_facade.dart';
import 'package:meeting_place_control_plane_api/src/api/did_document_resolve/route.dart';
import 'package:meeting_place_control_plane_api/src/core/service/did_document/did_document_service.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

class _FakeApplicationFacade implements ApplicationFacade {
  _FakeApplicationFacade({required this.resolveResult});

  final Future<Map<String, dynamic>> Function(String segment) resolveResult;

  @override
  Future<Map<String, dynamic>> resolveDidDocumentBySegment(String segment) =>
      resolveResult(segment);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Request _request(String segment) =>
    Request('GET', Uri.parse('http://localhost:3000/user/$segment/did.json'));

void main() {
  group('didDocumentResolve route', () {
    test('returns 200 with DID document on success', () async {
      const segment = 'alice';
      final doc = {
        'id': 'did:web:example.com:user:$segment',
        '@context': ['https://www.w3.org/ns/did/v1'],
      };
      final facade = _FakeApplicationFacade(resolveResult: (_) async => doc);

      final response = await didDocumentResolve(
        _request(segment),
        facade,
        segment,
      );

      expect(response.statusCode, 200);
      expect(response.headers['content-type'], 'application/did+ld+json');
      expect(jsonDecode(await response.readAsString()), doc);
    });

    test('returns 404 JSON when document is not found', () async {
      const segment = 'unknown';
      final facade = _FakeApplicationFacade(
        resolveResult: (_) async => throw DidDocumentNotFound(),
      );

      final response = await didDocumentResolve(
        _request(segment),
        facade,
        segment,
      );

      expect(response.statusCode, 404);
      expect(response.headers['content-type'], 'application/json');
      final body = jsonDecode(await response.readAsString());
      expect(body['error'], 'not_found');
    });

    test('returns 500 JSON on unexpected error', () async {
      const segment = 'alice';
      final facade = _FakeApplicationFacade(
        resolveResult: (_) async => throw Exception('storage failure'),
      );

      final response = await didDocumentResolve(
        _request(segment),
        facade,
        segment,
      );

      expect(response.statusCode, 500);
      expect(response.headers['content-type'], 'application/json');
      final body = jsonDecode(await response.readAsString());
      expect(body['error'], 'server_error');
    });
  });
}
