import 'dart:convert';
import 'dart:typed_data';

import 'auth_did_manager.dart';
import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart' show DidManager;

import '../../../utils/date_time.dart';
import 'auth_response.dart';

class AuthClient {
  AuthClient({
    required List<dynamic> privateJwks,
    DidManager? recipientDidManager,
  }) : _privateJwks = privateJwks,
       _recipientDidManager = recipientDidManager;
  final List<dynamic> _privateJwks;
  final DidManager? _recipientDidManager;

  Future<AuthenticationResponse> unpackChallengeResponse(
    String authChallengeResponse,
    String didResolverUrl,
  ) async {
    late _VerifiedChallengeResponse challengeResponse;

    try {
      challengeResponse = await _unpackDidCommMessageFromBase64(
        authChallengeResponse,
        didResolverUrl,
      );
    } catch (e) {
      return AuthenticationResponse.asInvalidChallengeResponse();
    }

    if (_isDidcommMessageExpired(challengeResponse.message)) {
      return AuthenticationResponse.asChallengeRequestExpired();
    }

    if (challengeResponse.message.body!['challenge'] == null) {
      return AuthenticationResponse.asInvalidChallengeResponse();
    }

    return AuthenticationResponse(
      type: AuthenticationResponseType.didcommChallengeOk,
      did: challengeResponse.message.from ?? '',
      challenge: challengeResponse.message.body!['challenge'],
      verificationMethod: challengeResponse.verificationMethod,
    );
  }

  Future<_VerifiedChallengeResponse> _unpackDidCommMessageFromBase64(
    String base64Data,
    String didResolverUrl,
  ) async {
    Base64Codec base64 = const Base64Codec();
    String data = base64.normalize(base64Data);
    return await _unpack(utf8.decode(base64Url.decode(data)), didResolverUrl);
  }

  Future<_VerifiedChallengeResponse> _unpack(
    String encryptedMessageAsString,
    String didResolverUrl,
  ) async {
    final encrypted = EncryptedMessage.fromJson(
      jsonDecode(encryptedMessageAsString),
    );

    final recipientDidManager = await _getRecipientDidManager();
    final decrypted = await encrypted.unpack(
      recipientDidManager: recipientDidManager,
    );
    if (!SignedMessage.isSignedMessage(decrypted)) {
      throw Exception('Challenge response must be a signed DIDComm message');
    }

    final signedMessage = SignedMessage.fromJson(decrypted);
    if (!await signedMessage.areSignaturesValid()) {
      throw Exception('Challenge response signature verification failed');
    }

    final unpacked = await signedMessage.unpack();
    final message = PlainTextMessage.fromJson(unpacked);
    message.validateConsistencyWithSignedMessage(
      signedMessage,
      messageWrappingType: MessageWrappingType.signedPlaintext,
    );
    return _VerifiedChallengeResponse(
      message: message,
      verificationMethod: signedMessage.signatures.first.header.keyId,
    );
  }

  Future<DidManager> _getRecipientDidManager() async {
    if (_recipientDidManager != null) {
      return _recipientDidManager;
    }
    final authDidManager = await AuthDidManager.getInstance(jwks: _privateJwks);
    return authDidManager.didManager;
  }

  bool _isDidcommMessageExpired(PlainTextMessage message) {
    return message.expiresTime == null ||
        message.expiresTime!.isBefore(nowUtc());
  }

  static Uint8List decodeBase64Url(String input) {
    // Add padding if needed
    String normalized = base64Url.normalize(input);
    return base64Url.decode(normalized);
  }

  String addBase64Padding(String base64String) {
    // Calculate padding needed
    int remainder = base64String.length % 4;

    if (remainder > 0) {
      int paddingLength = 4 - remainder;
      base64String += '=' * paddingLength;
    }

    return base64String;
  }
}

class _VerifiedChallengeResponse {
  _VerifiedChallengeResponse({
    required this.message,
    required this.verificationMethod,
  });

  final PlainTextMessage message;
  final String verificationMethod;
}
