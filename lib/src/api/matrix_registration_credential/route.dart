import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';

import '../application_facade.dart';
import '../request_validation_exception.dart';
import '../../core/config/config.dart';
import '../../core/config/env_config.dart';
import 'request_model.dart';
import 'response_error_model.dart';
import 'response_model.dart';

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

  if (asUri.hasScheme) {
    if (asUri.scheme != 'https') return null;
    if (asUri.host.isEmpty) return null;
    return Uri(
      scheme: 'https',
      host: asUri.host,
      port: asUri.hasPort ? asUri.port : null,
    ).toString();
  }

  // Treat as bare hostname (optionally with port)
  final hostUri = Uri.tryParse('https://$trimmed');
  if (hostUri == null || hostUri.host.isEmpty) return null;

  return Uri(
    scheme: 'https',
    host: hostUri.host,
    port: hostUri.hasPort ? hostUri.port : null,
  ).toString();
}
