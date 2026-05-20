import 'package:shelf/shelf.dart';
import '../request_validation_exception.dart';
import 'request_model.dart';
import 'response_model.dart';
import '../application_facade.dart';
import '../../core/secret_manager/secret_manager.dart';
import '../../core/service/auth/challenge_purpose.dart';
import '../../core/service/auth/didcomm_auth_challenge.dart';

Future<Response> matrixChallenge(
  Request request,
  ApplicationFacade facade,
) async {
  try {
    final challengeRequest = MatrixChallengeRequest.fromRequestParams(
      await request.readAsString(),
    );

    final authToken = await DIDCommAuthChallenge.generateAuthChallenge(
      did: challengeRequest.did,
      secretManager: SecretManager.get(),
      purpose: ChallengePurpose.matrixToken,
    );

    return Response.ok(
      MatrixChallengeResponse(challenge: authToken).toString(),
    );
  } on RequestValidationException catch (e) {
    return Response.badRequest(body: e.toString());
  } catch (e, stackTrace) {
    facade.logError(
      'Matrix challenge failed: $e',
      error: e,
      stackTrace: stackTrace,
    );
    return Response.internalServerError();
  }
}
