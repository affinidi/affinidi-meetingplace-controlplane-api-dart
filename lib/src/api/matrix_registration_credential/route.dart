import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';

import '../application_facade.dart';
import '../../server/utils.dart';
import '../../utils/supported_curve.dart';

Future<Response> matrixRegistrationToken(
  Request request,
  ApplicationFacade facade,
) async {
  try {
    final bodyText = await request.readAsString();
    final body = bodyText.trim().isEmpty
        ? <String, dynamic>{}
        : (jsonDecode(bodyText) as Map<String, dynamic>);
    final homeserver = (body['homeserver'] as String?)?.trim();
    if (homeserver == null || homeserver.isEmpty) {
      return Response.badRequest(
        body: jsonEncode({'error': 'homeserver is required'}),
      );
    }

    final authDid = getAuthDid(request);
    final token = await _issueMatrixToken(
      facade: facade,
      did: authDid,
      homeserver: homeserver,
    );

    return Response.ok(
      jsonEncode({'token': token, 'did': authDid}),
      headers: {'content-type': 'application/json'},
    );
  } catch (e, stackTrace) {
    facade.logError(
      'Error on matrix registration token',
      error: e,
      stackTrace: stackTrace,
    );
    return Response.internalServerError(body: 'Unable to issue token');
  }
}

Future<String> _issueMatrixToken({
  required ApplicationFacade facade,
  required String did,
  required String homeserver,
}) async {
  final serverName = _extractMatrixServerName(homeserver);
  final audience = _extractAudience(homeserver);
  final subject = sha256.convert(utf8.encode('$did|$serverName')).toString();

  final authorizer = await facade.buildDidCommAuthorizer();
  final privateJwkDoc = authorizer.jwk.firstWhere(
    (doc) => doc['privateKeyJwk']?['crv'] == SupportedCurve.p256.value,
    orElse: () =>
        throw StateError('${SupportedCurve.p256.value} private JWK not found'),
  );
  final privateJwk = Map<String, dynamic>.from(privateJwkDoc['privateKeyJwk']);
  final key = JWTKey.fromJWK(privateJwk);
  final controlPlaneDid =
      (await facade.config.didDocumentManager.getDidDocument()).id;

  final jwt = JWT(
    {},
    subject: subject,
    issuer: controlPlaneDid,
    audience: Audience([audience]),
    jwtId: const Uuid().v4(),
  );
  return jwt.sign(
    key,
    algorithm: JWTAlgorithm.ES256,
    expiresIn: Duration(seconds: facade.config.matrixTokenExpirySeconds),
  );
}

String _extractMatrixServerName(String homeserver) {
  final normalized = homeserver.contains('://')
      ? homeserver
      : 'http://$homeserver';
  final uri = Uri.parse(normalized);
  final host = uri.host.trim();
  if (host.isEmpty) {
    throw ArgumentError('Invalid homeserver');
  }
  return host;
}

String _extractAudience(String homeserver) {
  final normalized = homeserver.contains('://')
      ? homeserver
      : 'http://$homeserver';
  final uri = Uri.parse(normalized);
  final host = uri.host.trim();
  if (host.isEmpty) {
    throw ArgumentError('Invalid homeserver');
  }
  final authority = uri.hasPort ? '$host:${uri.port}' : host;
  final scheme = uri.scheme.trim().isEmpty ? 'http' : uri.scheme.trim();
  return '$scheme://$authority';
}
