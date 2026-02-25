import 'dart:convert';
import '../../../utils/date_time.dart';
import 'auth_response.dart';
import 'dart:typed_data';
import 'auth_did_manager.dart';
import 'package:didcomm/didcomm.dart';

class AuthClient {
  AuthClient({required List<dynamic> privateJwks}) : _privateJwks = privateJwks;
  final List<dynamic> _privateJwks;

  Future<AuthenticationResponse> unpackChallengeResponse(
    String authChallengeResponse,
    String didResolverUrl,
  ) async {
    late PlainTextMessage plaintextMessage;

    try {
      plaintextMessage = await unpackDidCommMessageFromBase64(
        authChallengeResponse,
        didResolverUrl,
      );
    } catch (e) {
      return AuthenticationResponse.asInvalidChallengeResponse();
    }

    if (_isDidcommMessageExpired(plaintextMessage)) {
      return AuthenticationResponse.asChallengeRequestExpired();
    }

    if (plaintextMessage.body!['challenge'] == null) {
      return AuthenticationResponse.asInvalidChallengeResponse();
    }

    return AuthenticationResponse(
      type: AuthenticationResponseType.didcommChallengeOk,
      did: plaintextMessage.from ?? '',
      challenge: plaintextMessage.body!['challenge'],
    );
  }

  Future<PlainTextMessage> unpackDidCommMessageFromBase64(
    String base64Data,
    String didResolverUrl,
  ) async {
    Base64Codec base64 = const Base64Codec();
    String data = base64.normalize(base64Data);
    return await unpack(utf8.decode(base64Url.decode(data)), didResolverUrl);
  }

  Future<PlainTextMessage> unpack(
    String encryptedMessageAsString,
    String didResolverUrl,
  ) async {
    final encrypted = EncryptedMessage.fromJson(
      jsonDecode(encryptedMessageAsString),
    );

    final authDidManager = await AuthDidManager.getInstance(jwks: _privateJwks);
    final decrypted = await encrypted.unpack(
      recipientDidManager: authDidManager.didManager,
    );

    return PlainTextMessage.fromJson(
      jsonDecode(
        utf8.decode(base64Decode(addBase64Padding(decrypted['payload']))),
      ),
    );
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
