import 'dart:convert';
import 'package:shelf/shelf.dart';

import '../application_facade.dart';
import 'request_model.dart';
import 'response_model.dart';

Future<Response> updateOffersVrcCount(
  Request request,
  ApplicationFacade facade,
  String authDid,
) async {
  try {
    final body = await request.readAsString();
    final input = UpdateOffersVrcCountRequest.fromJson(
      jsonDecode(body) as Map<String, dynamic>,
    );

    final updatedOffers = await facade.updateOffersVrcCount(
      input.score,
      input.offerLinks,
    );

    return Response.ok(
      UpdateOffersVrcCountResponse(updatedOffers: updatedOffers).toJson(),
      headers: {'content-type': 'application/json'},
    );
  } catch (e, st) {
    facade.logError(
      'Batch update VRC count failed: $e',
      error: e,
      stackTrace: st,
    );
    return Response.internalServerError();
  }
}
