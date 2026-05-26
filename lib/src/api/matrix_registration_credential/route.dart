import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';

import '../application_facade.dart';
import '../../core/config/config.dart';
import '../../core/service/auth/auth_response.dart';
import '../../core/service/auth/didcomm_auth.dart';
import '../../core/service/auth/didcomm_auth_builder.dart';
import '../../utils/supported_curve.dart';

Future<Response> matrixRegistrationToken(
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
    final homeserver = (body['homeserver'] as String?)?.trim();
    if (homeserver == null || homeserver.isEmpty) {
      return Response.badRequest(
        body: jsonEncode({'error': 'homeserver is required'}),
      );
    }
    final challenge = (body['challenge'] as String?)?.trim();
    if (challenge == null || challenge.isEmpty) {
      return Response.badRequest(
        body: jsonEncode({'error': 'challenge is required'}),
      );
    }

    final authorizer = await DIDCommAuthBuilder(
      logger: facade.config.logger,
    ).build();
    final authResponse = await authorizer.unpackChallengeResponse(
      challenge,
      Config().get('auth')['didResolverUrl'],
    );
    if (authResponse.type != AuthenticationResponseType.didcommChallengeOk) {
      return Response.badRequest(
        body: jsonEncode({'error': authResponse.type.name}),
      );
    }
    final jwtStatus = authorizer.verifyAuthChallengeToken(
      authResponse.did,
      authResponse.challenge,
    );
    if (jwtStatus != JWTStatus.valid) {
      return Response.badRequest(body: jsonEncode({'error': jwtStatus.name}));
    }

    final token = await _issueMatrixToken(
      facade: facade,
      permanentChannelDid: authResponse.did,
      homeserver: homeserver,
    );

    return Response.ok(
      jsonEncode({'token': token}),
      headers: {'content-type': 'application/json'},
    );
  } on FormatException {
    return Response.badRequest(body: jsonEncode({'error': 'Invalid JSON'}));
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
  required String permanentChannelDid,
  required String homeserver,
}) async {
  final serverName = _extractMatrixServerName(homeserver);
  final audience = _extractAudience(homeserver);
  final subject = sha256
      .convert(utf8.encode('$permanentChannelDid|$serverName'))
      .toString();

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
