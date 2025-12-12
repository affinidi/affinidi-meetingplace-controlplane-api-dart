import 'dart:convert';

import '../../core/logger/logger.dart';
import '../../core/service/auth/didcomm_auth.dart';
import 'package:shelf/shelf.dart';

import '../../core/service/auth/didcomm_auth_builder.dart';

enum AuthErrorCodes {
  authorizationTokenNotProvided('AUTHORIZATION_TOKEN_NOT_PROVIDED'),
  authorizationTokenVerificationFailed(
    'AUTHORIZATION_TOKEN_VERIFICATION_FAILED',
  ),
  authorizationTokenExpired('AUTHORIZATION_TOKEN_EXPIRED');

  const AuthErrorCodes(this.value);

  final String value;
}

Middleware authorize(Logger logger) => (innerHandler) {
  return (Request request) async {
    final authHeader = getAuthHeader(request.headers);
    final authToken = authHeader?.replaceFirst(
      RegExp(r'^[Bb][Ee][Aa][Rr][Ee][Rr] '),
      '',
    );

    if (authToken == null) {
      return Response.forbidden(
        JsonEncoder().convert({
          'errorCode': AuthErrorCodes.authorizationTokenNotProvided.value,
          'errorMessage': 'No authorization token provided',
        }),
      );
    }

    final authorizer = await DIDCommAuthBuilder(logger: logger).build();

    final authTokenVerification = authorizer.verifyAuthToken(authToken);
    if (authTokenVerification.status != JWTStatus.valid) {
      return Response.unauthorized(
        JsonEncoder().convert({
          'errorCode': AuthErrorCodes.authorizationTokenExpired.value,
          'errorMessage': 'Authorization token verification failed',
        }),
      );
    }

    request = request.change(context: {'authDid': authTokenVerification.did});

    return Future.sync(() => innerHandler(request)).then((response) {
      return response;
    });
  };
};

String? getAuthHeader(Map<String, String> headers) {
  if (headers['authorization'] != null) return headers['authorization'];
  if (headers['Authorization'] != null) return headers['Authorization'];
  if (headers['AUTHORIZATION'] != null) return headers['AUTHORIZATION'];
  return null;
}
