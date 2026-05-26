import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../../server/utils.dart';
import '../application_facade.dart';
import '../../core/service/did_document/did_document_service.dart';

Future<Response> didDocumentUpload(
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
    final body = decoded;
    final didDocument = body['didDocument'];
    if (didDocument is! Map<String, dynamic>) {
      return Response.badRequest(
        body: jsonEncode({'error': 'didDocument is required'}),
      );
    }
    final controlProof = body['controlProof'];
    if (controlProof is! Map<String, dynamic>) {
      return Response.badRequest(
        body: jsonEncode({'error': 'controlProof is required'}),
      );
    }
    final proof = body['proof'];
    if (proof is! Map<String, dynamic>) {
      return Response.badRequest(
        body: jsonEncode({'error': 'proof is required'}),
      );
    }
    final result = await facade.uploadDidDocument(
      authDid: getAuthDid(request),
      didDocument: didDocument,
      controlProof: Map<String, dynamic>.from(controlProof),
      proof: Map<String, dynamic>.from(proof),
    );
    return Response.ok(
      jsonEncode(result),
      headers: {'content-type': 'application/json'},
    );
  } on FormatException {
    return Response.badRequest(body: jsonEncode({'error': 'Invalid JSON'}));
  } on InvalidDidDocumentInput catch (e) {
    return Response.badRequest(body: jsonEncode({'error': e.message}));
  } catch (e, stackTrace) {
    facade.logError(
      'Error on did document upload',
      error: e,
      stackTrace: stackTrace,
    );
    return Response.internalServerError(body: 'Unable to upload DID document');
  }
}
