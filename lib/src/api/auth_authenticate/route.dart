import 'package:shelf/shelf.dart';
import '../request_validation_exception.dart';
import '../../core/service/auth/didcomm_auth_builder.dart';
import 'request_model.dart';
import 'response_error_model.dart';
import 'response_model.dart';
import '../application_facade.dart';
import '../../core/config/config.dart';
import '../../core/service/auth/auth_response.dart';
import '../../core/service/auth/didcomm_auth.dart';
import '../../utils/date_time.dart';

Future<Response> authAuthenticate(
  Request request,
  ApplicationFacade facade,
) async {
  try {
    final requestParams = AuthAuthenticateRequest.fromRequestParams(
      await request.readAsString(),
    );

    final authorizer = await DIDCommAuthBuilder(
      logger: facade.config.logger,
    ).build();

    final AuthenticationResponse authResponse = await authorizer
        .unpackChallengeResponse(
          requestParams.challengeResponse,
          Config().get('auth')['didResolverUrl'],
        );

    if (authResponse.type != AuthenticationResponseType.didcommChallengeOk) {
      return Response.badRequest(
        body: AuthAuthenticateErrorResponse.invalidChallengeResponse(
          authResponse.type.name,
        ).toString(),
      );
    }

    final JWTStatus jwtStatus = authorizer.verifyAuthChallengeToken(
      authResponse.did,
      authResponse.challenge,
    );

    if (jwtStatus != JWTStatus.valid) {
      return Response.badRequest(
        body: AuthAuthenticateErrorResponse.invalidChallengeResponse(
          jwtStatus.name,
        ).toString(),
      );
    }

    final authConfig = Config().get('auth');
    final String accessToken = authorizer.getAuthToken(
      authResponse.did,
      authConfig['accessTokenExpiryInMinutes'],
    );

    final DateTime accessExpiresAt = nowUtc().add(
      Duration(minutes: authConfig['accessTokenExpiryInMinutes']),
    );

    final String refreshToken = authorizer.getAuthRefreshToken(
      authResponse.did,
      authConfig['refreshTokenExpiryInMinutes'],
    );

    final DateTime refreshExpiresAt = nowUtc().add(
      Duration(minutes: authConfig['refreshTokenExpiryInMinutes']),
    );

    return Response.ok(
      AuthAuthenticateResponse(
        accessToken: accessToken,
        refreshToken: refreshToken,
        accessExpiresAt: accessExpiresAt,
        refreshExpiresAt: refreshExpiresAt,
      ).toString(),
    );
  } on RequestValidationException catch (e) {
    return Response.badRequest(body: e.toString());
  } catch (e, stackTrace) {
    facade.logError(
      'Authentication failed: $e',
      error: e,
      stackTrace: stackTrace,
    );
    return Response.internalServerError();
  }
}
