import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../../server/utils.dart';
import '../application_facade.dart';
import '../../core/service/did_document/did_document_service.dart';

Future<Response> didDocumentUpdate(Request request, ApplicationFacade facade) async {
  try {
    final bodyText = await request.readAsString();
    final body = bodyText.trim().isEmpty
        ? <String, dynamic>{}
        : jsonDecode(bodyText) as Map<String, dynamic>;
    final didDocument = body['didDocument'];
    if (didDocument is! Map<String, dynamic>) {
      return Response.badRequest(
        body: jsonEncode({'error': 'didDocument is required'}),
      );
    }
    final result = await facade.updateDidDocument(
      authDid: getAuthDid(request),
      didDocument: didDocument,
    );
    return Response.ok(
      jsonEncode(result),
      headers: {'content-type': 'application/json'},
    );
  } on DidDocumentNotFound {
    return Response.notFound(jsonEncode({'error': 'DID document not found'}));
  } on InvalidDidDocumentInput catch (e) {
    return Response.badRequest(body: jsonEncode({'error': e.message}));
  } catch (e, stackTrace) {
    facade.logError(
      'Error on did document update',
      error: e,
      stackTrace: stackTrace,
    );
    return Response.internalServerError(body: 'Unable to update DID document');
  }
}
