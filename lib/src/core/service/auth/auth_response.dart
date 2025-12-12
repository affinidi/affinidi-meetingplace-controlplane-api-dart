enum AuthenticationResponseType {
  unknown,
  didcommChallengeOk,
  challengeRequestExpired,
  challengeRequestPayloadExpired,
  invalidChallengeResponse,
  invalidChallengeRequest,
}

class AuthenticationResponse {
  AuthenticationResponse({
    required this.type,
    this.did = '',
    this.challenge = '',
  });

  factory AuthenticationResponse.asInvalidChallengeResponse() {
    return AuthenticationResponse(
      type: AuthenticationResponseType.invalidChallengeResponse,
    );
  }

  factory AuthenticationResponse.asChallengeRequestExpired() {
    return AuthenticationResponse(
      type: AuthenticationResponseType.challengeRequestExpired,
    );
  }
  AuthenticationResponseType type;
  String did = '';
  String challenge = '';
}
