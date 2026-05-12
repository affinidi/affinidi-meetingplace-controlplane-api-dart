import 'dart:convert';

import '../../core/service/matrix/matrix_token.dart';
import '../../core/service/matrix/matrix_token_service.dart';
import '../request_validation_exception.dart';
import 'request_model.dart';
import '../application_facade.dart';
import 'package:shelf/shelf.dart';

import '../../core/config/config.dart';
import '../../core/service/auth/auth_response.dart';
import '../../core/service/auth/didcomm_auth_builder.dart';
import 'response_model.dart';

Future<Response> matrixToken(Request request, ApplicationFacade facade) async {
  try {
    final matrixTokenRequest = MatrixTokenRequest.fromRequestParams(
      await request.readAsString(),
    );

    final authorizer = await DIDCommAuthBuilder(
      logger: facade.config.logger,
    ).build();

    final String authDid;
    try {
      authDid = await authorizer.authenticateChallengeResponse(
        matrixTokenRequest.challengeResponse,
        Config().get('auth')['didResolverUrl'],
      );
    } on ChallengeAuthException {
      facade.logInfo('Challenge response is invalid or could not be verified.');

      return Response.badRequest(
        body: jsonEncode({
          'errorCode': 'CHALLENGE_RESPONSE_INVALID',
          'errorMessage':
              'Challenge response is invalid or could not be verified.',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final credential = await MatrixTokenService.issueToken(
      did: authDid,
      homeserver: matrixTokenRequest.homeserver,
    );

    return Response.ok(MatrixTokenResponse(token: credential).toString());
  } on RequestValidationException catch (e) {
    return Response.badRequest(body: e.toString());
  } catch (e, stackTrace) {
    facade.logError(
      'Error when issuing matrix credential: $e',
      error: e,
      stackTrace: stackTrace,
    );

    return Response.internalServerError(body: 'Unable to issue credential');
  }
}
