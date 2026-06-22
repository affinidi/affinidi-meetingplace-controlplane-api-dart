import 'package:shelf/shelf.dart';
import '../request_validation_exception.dart';
import 'request_model.dart';
import 'response_model.dart';
import '../application_facade.dart';
import '../../core/secret_manager/secret_manager.dart';
import '../../core/service/auth/challenge_purpose.dart';
import '../../core/service/auth/didcomm_auth_challenge.dart';

Future<Response> authChallenge(
  Request request,
  ApplicationFacade facade,
) async {
  try {
    final authChallengeRequest = AuthChallengeRequest.fromRequestParams(
      await request.readAsString(),
    );

    final challenge = await DIDCommAuthChallenge.generateAuthChallenge(
      did: authChallengeRequest.did,
      secretManager: SecretManager.get(),
      purpose: ChallengePurpose.authenticate,
    );

    return Response.ok(AuthChallengeResponse(challenge: challenge).toString());
  } on RequestValidationException catch (e) {
    return Response.badRequest(body: e.toString());
  } catch (e, stackTrace) {
    facade.logError(
      'Auth challenge failed: $e',
      error: e,
      stackTrace: stackTrace,
    );
    return Response.internalServerError();
  }
}
