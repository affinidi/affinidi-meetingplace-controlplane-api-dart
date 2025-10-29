import 'package:shelf/shelf.dart';
import '../request_validation_exception.dart';
import 'request_model.dart';
import 'response_model.dart';
import '../application_facade.dart';
import '../../adapter/secret_manager/secret_manager.dart';
import '../../core/service/auth/didcomm_auth_challenge.dart';

Future<Response> authChallenge(
    Request request, ApplicationFacade facade) async {
  try {
    final authChallengeRequest = AuthChallengeRequest.fromRequestParams(
      await request.readAsString(),
    );

    final authToken = await DIDCommAuthChallenge.generateAuthChallenge(
      authChallengeRequest.did,
      SecretManager.get(),
    );

    return Response.ok(
      AuthChallengeResponse(
        challenge: authToken,
      ).toString(),
    );
  } on RequestValidationException catch (e) {
    return Response.badRequest(body: e.toString());
  } catch (e, stackTrace) {
    facade.logError('Auth challenge failed: $e',
        error: e, stackTrace: stackTrace);
    return Response.internalServerError();
  }
}
