import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';

import '../application_facade.dart';
import '../request_validation_exception.dart';
import '../../core/config/config.dart';
import '../../core/config/env_config.dart';
import '../../core/service/auth/auth_response.dart';
import '../../core/service/auth/challenge_purpose.dart';
import '../../core/service/auth/didcomm_auth.dart';
import '../../core/service/auth/didcomm_auth_builder.dart';
import '../../utils/supported_curve.dart';
import 'request_model.dart';
import 'response_error_model.dart';
import 'response_model.dart';

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
    final VerifyAuthChallengeResult verifyResult = authorizer
        .verifyAuthChallengeToken(
          authResponse.did,
          authResponse.challenge,
          ChallengePurpose.matrixToken,
        );
    if (verifyResult.status != JWTStatus.valid) {
      return Response.badRequest(
        body: jsonEncode({'error': verifyResult.status.name}),
      );
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

Future<Response> matrixRegistrationCredential(
  Request request,
  ApplicationFacade facade,
) async {
  try {
    final bodyRaw = await request.readAsString();
    final requestModel = MatrixRegistrationCredentialRequest.fromRequestParams(
      bodyRaw,
    );

    final homeserverAud = _normalizeHomeserverToAudience(
      requestModel.homeserver,
    );

    if (homeserverAud == null) {
      return Response.badRequest(
        body: MatrixRegistrationCredentialErrorResponse.invalidHomeserver(
          'homeserver must be a hostname or https:// URL',
        ).toString(),
      );
    }

    final did = request.context['authDid'] as String;

    final credential = _issueMatrixRegistrationCredential(
      did: did,
      audience: homeserverAud,
    );

    return Response.ok(
      MatrixRegistrationCredentialResponse(
        credential: credential,
        did: did,
      ).toString(),
    );
  } on RequestValidationException catch (e) {
    return Response.badRequest(body: e.toString());
  } catch (e, stackTrace) {
    facade.logError(
      'Matrix registration credential issuance failed: $e',
      error: e,
      stackTrace: stackTrace,
    );
    return Response.internalServerError();
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

String _issueMatrixRegistrationCredential({
  required String did,
  required String audience,
}) {
  final issuer = getEnv('CONTROL_PLANE_DID');
  final didcommauth = Config().getSecret('didcommauth');

  if (didcommauth == null) {
    throw Exception('Secret didcommauth not found');
  }

  final p256JwkDoc = didcommauth.firstWhere(
    (doc) => doc['privateKeyJwk']?['crv'] == 'P-256',
    orElse: () => null,
  );
  if (p256JwkDoc == null) {
    throw Exception('No P-256 signing key found in didcommauth secret');
  }

  final privateJwk = Map<String, dynamic>.from(p256JwkDoc['privateKeyJwk']);
  final kid = privateJwk['kid'] as String?;
  final signingKey = JWTKey.fromJWK(privateJwk);

  final expiryDays =
      int.tryParse(
        getEnvOrNull('MATRIX_REGISTRATION_CREDENTIAL_EXPIRY_DAYS') ?? '',
      ) ??
      30;

  final jwt = JWT(
    {'scope': 'matrix.register'},
    subject: did,
    audience: Audience([audience]),
    issuer: issuer,
    header: kid == null ? null : {'kid': kid, 'typ': 'JWT'},
  );

  return jwt.sign(
    signingKey,
    algorithm: JWTAlgorithm.ES256,
    expiresIn: Duration(days: expiryDays),
  );
}

String? _normalizeHomeserverToAudience(String homeserver) {
  final trimmed = homeserver.trim();
  if (trimmed.isEmpty) return null;

  final asUri = Uri.tryParse(trimmed);
  if (asUri == null) return null;

  // TODO: remove before merging - this is to allow testing with localhost
  // without needing to use HTTPS, but we don't want to allow it in production
  final allowLocalhost =
      getEnvOrNull('MATRIX_REGISTRATION_CREDENTIAL_ALLOW_LOCALHOST') != null;

  if (asUri.hasScheme) {
    if (asUri.scheme == 'http' && allowLocalhost && asUri.host == 'localhost') {
      return Uri(
        scheme: 'http',
        host: asUri.host,
        port: asUri.hasPort ? asUri.port : null,
      ).toString();
    }
    if (asUri.scheme != 'https') return null;
    if (asUri.host.isEmpty) return null;
    return Uri(
      scheme: 'https',
      host: asUri.host,
      port: asUri.hasPort ? asUri.port : null,
    ).toString();
  }

  // Treat as bare hostname (optionally with port)
  if (allowLocalhost) {
    final localhostUri = Uri.tryParse('http://$trimmed');
    if (localhostUri != null && localhostUri.host == 'localhost') {
      return Uri(
        scheme: 'http',
        host: localhostUri.host,
        port: localhostUri.hasPort ? localhostUri.port : null,
      ).toString();
    }
  }

  final hostUri = Uri.tryParse('https://$trimmed');
  if (hostUri == null || hostUri.host.isEmpty) return null;

  return Uri(
    scheme: 'https',
    host: hostUri.host,
    port: hostUri.hasPort ? hostUri.port : null,
  ).toString();
}
