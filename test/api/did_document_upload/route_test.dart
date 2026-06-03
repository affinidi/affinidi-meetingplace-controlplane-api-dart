import 'dart:convert';

import 'package:meeting_place_control_plane_api/src/api/application_facade.dart';
import 'package:meeting_place_control_plane_api/src/api/did_document_upload/route.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

class _FakeApplicationFacade implements ApplicationFacade {
  _FakeApplicationFacade();

  String? capturedAuthDid;
  Map<String, dynamic>? capturedDidDocument;
  Map<String, dynamic>? capturedControlProof;
  Map<String, dynamic>? capturedProof;

  @override
  Future<Map<String, dynamic>> uploadDidDocument({
    required String authDid,
    required String authVerificationMethod,
    required Map<String, dynamic> didDocument,
    required Map<String, dynamic> controlProof,
    required Map<String, dynamic> proof,
  }) async {
    capturedAuthDid = authDid;
    capturedDidDocument = didDocument;
    capturedControlProof = controlProof;
    capturedProof = proof;
    return {
      'did': 'did:web:example.com:user:alice',
      'segment': 'alice',
      'didDocUrl': 'https://example.com/user/alice/did.json',
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _ThrowingApplicationFacade implements ApplicationFacade {
  @override
  Future<Map<String, dynamic>> uploadDidDocument({
    required String authDid,
    required String authVerificationMethod,
    required Map<String, dynamic> didDocument,
    required Map<String, dynamic> controlProof,
    required Map<String, dynamic> proof,
  }) async {
    throw Exception('storage failure');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Request _request(Map<String, dynamic> body) => Request(
  'POST',
  Uri.parse('http://localhost:3000/v1/did-document/upload'),
  body: jsonEncode(body),
  context: {
    'authDid': 'did:key:zAlice123',
    'authVerificationMethod': 'did:key:zAlice123#control-1',
  },
);

void main() {
  group('didDocumentUpload route', () {
    test('rejects string controlProof payloads', () async {
      final response = await didDocumentUpload(
        _request({
          'didDocument': {'id': 'did:web:example.com:user:alice'},
          'controlProof': 'signed-jws',
          'proof': {
            'type': 'JsonWebSignature2020',
            'created': '2026-01-01T00:00:00Z',
            'verificationMethod': 'did:web:example.com:user:alice#auth',
            'proofPurpose': 'authentication',
            'jws': 'proof-jws',
          },
        }),
        _FakeApplicationFacade(),
      );

      expect(response.statusCode, 400);
      expect(
        await response.readAsString(),
        contains('controlProof is required'),
      );
    });

    test('passes proof objects through to the facade', () async {
      final facade = _FakeApplicationFacade();
      final controlProof = {
        'type': 'JsonWebSignature2020',
        'created': '2026-01-01T00:00:00Z',
        'verificationMethod': 'did:key:zAlice123#control-1',
        'proofPurpose': 'authentication',
        'jws': 'control-jws',
      };
      final proof = {
        'type': 'JsonWebSignature2020',
        'created': '2026-01-01T00:00:00Z',
        'verificationMethod': 'did:web:example.com:user:alice#auth',
        'proofPurpose': 'authentication',
        'jws': 'proof-jws',
      };

      final response = await didDocumentUpload(
        _request({
          'didDocument': {'id': 'did:web:example.com:user:alice'},
          'controlProof': controlProof,
          'proof': proof,
        }),
        facade,
      );

      expect(response.statusCode, 200);
      expect(facade.capturedAuthDid, 'did:key:zAlice123');
      expect(facade.capturedControlProof, controlProof);
      expect(facade.capturedProof, proof);
    });

    test('returns 500 JSON on unexpected upload errors', () async {
      final response = await didDocumentUpload(
        _request({
          'didDocument': {'id': 'did:web:example.com:user:alice'},
          'controlProof': {
            'type': 'JsonWebSignature2020',
            'created': '2026-01-01T00:00:00Z',
            'verificationMethod': 'did:key:zAlice123#control-1',
            'proofPurpose': 'authentication',
            'jws': 'control-jws',
          },
          'proof': {
            'type': 'JsonWebSignature2020',
            'created': '2026-01-01T00:00:00Z',
            'verificationMethod': 'did:web:example.com:user:alice#auth',
            'proofPurpose': 'authentication',
            'jws': 'proof-jws',
          },
        }),
        _ThrowingApplicationFacade(),
      );

      expect(response.statusCode, 500);
      expect(response.headers['content-type'], 'application/json');
      final body = jsonDecode(await response.readAsString());
      expect(body['error'], 'server_error');
      expect(body['message'], 'Unable to upload DID document');
    });
  });
}
