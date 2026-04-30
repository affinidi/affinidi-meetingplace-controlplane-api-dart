import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../application_facade.dart';
import '../../core/service/did_document/did_document_service.dart';

Future<Response> didDocumentResolve(
  Request request,
  ApplicationFacade facade,
  String segment,
) async {
  try {
    final doc = await facade.resolveDidDocumentBySegment(segment);
    return Response.ok(
      jsonEncode(doc),
      headers: {'content-type': 'application/did+ld+json'},
    );
  } on DidDocumentNotFound {
    return Response.notFound('DID document not found');
  } catch (e, stackTrace) {
    facade.logError(
      'Error resolving DID document',
      error: e,
      stackTrace: stackTrace,
    );
    return Response.internalServerError(body: 'Unable to resolve DID document');
  }
}
