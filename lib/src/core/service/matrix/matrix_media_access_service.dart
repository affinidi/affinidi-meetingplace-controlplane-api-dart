import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../config/config.dart';
import '../../logger/logger.dart';
import '../../web_manager/did_document_manager.dart';
import '../auth/didcomm_auth.dart';
import '../../../utils/supported_curve.dart';

class MatrixMediaAccessService {
  MatrixMediaAccessService({
    required Future<DIDCommAuth> Function() authorizerBuilder,
    required DidDocumentManager didDocumentManager,
    required Logger logger,
    required int matrixTokenExpirySeconds,
    required int matrixMediaAccessTokenExpirySeconds,
  }) : _authorizerBuilder = authorizerBuilder,
       _didDocumentManager = didDocumentManager,
       _logger = logger,
       _matrixTokenExpirySeconds = matrixTokenExpirySeconds,
       _matrixMediaAccessTokenExpirySeconds =
           matrixMediaAccessTokenExpirySeconds;

  static const String matrixJwtLoginType = 'org.matrix.login.jwt';
  static const String _mediaSigningSecretKey = 'matrixMediaSigningSecret';
  static const String _downloadUrlPathPrefix = '/v1/matrix/media/download/';
  static final RegExp _mediaIdPattern = RegExp(r'^[A-Za-z0-9_-]+$');
  static const int _maxDownloadsPerMinute = 20;
  static const Duration _downloadWindow = Duration(minutes: 1);
  static final Map<String, List<DateTime>> _downloadAttempts =
      <String, List<DateTime>>{};

  final Future<DIDCommAuth> Function() _authorizerBuilder;
  final DidDocumentManager _didDocumentManager;
  final Logger _logger;
  final int _matrixTokenExpirySeconds;
  final int _matrixMediaAccessTokenExpirySeconds;

  Future<String> issueLoginToken({
    required String did,
    required Uri homeserver,
  }) async {
    final normalizedHomeserver = _normalizeHomeserver(homeserver);
    final authorizer = await _authorizerBuilder();
    final privateJwkDoc = authorizer.jwk.firstWhere(
      (doc) => doc['privateKeyJwk']?['crv'] == SupportedCurve.p256.value,
      orElse: () => throw StateError(
        '${SupportedCurve.p256.value} private JWK not found',
      ),
    );
    final privateJwk = Map<String, dynamic>.from(
      privateJwkDoc['privateKeyJwk'],
    );
    final key = JWTKey.fromJWK(privateJwk);
    final controlPlaneDid = (await _didDocumentManager.getDidDocument()).id;

    final jwt = JWT(
      {},
      subject: _deriveMatrixLocalpart(did, normalizedHomeserver.host),
      issuer: controlPlaneDid,
      audience: Audience([_extractAudience(normalizedHomeserver)]),
      jwtId: const Uuid().v4(),
    );

    return jwt.sign(
      key,
      algorithm: JWTAlgorithm.ES256,
      expiresIn: Duration(seconds: _matrixTokenExpirySeconds),
    );
  }

  Future<String> createDownloadUrl({
    required String did,
    required Uri homeserver,
    required String roomId,
    required String mxcUri,
  }) async {
    _logger.info('Creating Matrix media download URL');
    final normalizedHomeserver = _normalizeHomeserver(homeserver);
    final normalizedRoomId = _normalizeRoomId(roomId);
    final parsedMedia = _parseMatrixMediaUri(mxcUri);
    final httpClient = http.Client();

    try {
      final accessToken = await _loginForAccessToken(
        did: did,
        homeserver: normalizedHomeserver,
        httpClient: httpClient,
      );

      await _assertRoomMembership(
        did: did,
        roomId: normalizedRoomId,
        homeserver: normalizedHomeserver,
        accessToken: accessToken,
        httpClient: httpClient,
      );
    } finally {
      httpClient.close();
    }

    final token = await _issueMediaAccessToken(
      did: did,
      roomId: normalizedRoomId,
      homeserver: normalizedHomeserver,
      parsedMedia: parsedMedia,
    );

    return '$_downloadUrlPathPrefix$token';
  }

  Future<MatrixDownloadedMedia> downloadMedia(String token) async {
    _logger.info('Downloading Matrix media through control plane');
    final access = await _verifyMediaAccessToken(token);
    _enforceRateLimit(access.did, access.mediaId);

    final homeserver = Uri.parse(access.homeserver);
    final httpClient = http.Client();

    try {
      final accessToken = await _loginForAccessToken(
        did: access.did,
        homeserver: homeserver,
        httpClient: httpClient,
      );

      await _assertRoomMembership(
        did: access.did,
        roomId: access.roomId,
        homeserver: homeserver,
        accessToken: accessToken,
        httpClient: httpClient,
      );

      return _fetchMedia(
        homeserver: homeserver,
        serverName: access.serverName,
        mediaId: access.mediaId,
        accessToken: accessToken,
        httpClient: httpClient,
      );
    } finally {
      httpClient.close();
    }
  }

  Uri _normalizeHomeserver(Uri homeserver) {
    if (!homeserver.isAbsolute || homeserver.scheme != 'https') {
      throw MatrixMediaAccessException.badRequest(
        'homeserver must be an absolute HTTPS URI',
      );
    }

    final host = homeserver.host.trim();
    if (host.isEmpty) {
      throw MatrixMediaAccessException.badRequest(
        'homeserver host is required',
      );
    }

    final authority = homeserver.hasPort ? '$host:${homeserver.port}' : host;
    return Uri.parse('https://$authority');
  }

  String _normalizeRoomId(String roomId) {
    final normalizedRoomId = roomId.trim();
    if (normalizedRoomId.isEmpty) {
      throw MatrixMediaAccessException.badRequest('room_id is required');
    }

    return normalizedRoomId;
  }

  _ParsedMatrixMediaUri _parseMatrixMediaUri(String mxcUri) {
    final uri = Uri.tryParse(mxcUri);
    final mediaId = uri?.pathSegments.length == 1
        ? uri!.pathSegments.first
        : '';
    final serverName = uri?.authority.trim() ?? '';

    if (uri == null ||
        uri.scheme != 'mxc' ||
        serverName.isEmpty ||
        mediaId.isEmpty) {
      throw MatrixMediaAccessException.badRequest(
        'media_uri must be a valid mxc URI',
      );
    }

    if (!_mediaIdPattern.hasMatch(mediaId)) {
      throw MatrixMediaAccessException.badRequest(
        'media_uri has an invalid media id',
      );
    }

    return _ParsedMatrixMediaUri(serverName: serverName, mediaId: mediaId);
  }

  String _deriveMatrixLocalpart(String did, String serverName) {
    return sha256.convert(utf8.encode('$did|$serverName')).toString();
  }

  String _deriveMatrixUserId(String did, String serverName) {
    return '@${_deriveMatrixLocalpart(did, serverName)}:$serverName';
  }

  String _extractAudience(Uri homeserver) {
    final authority = homeserver.hasPort
        ? '${homeserver.host}:${homeserver.port}'
        : homeserver.host;
    return '${homeserver.scheme}://$authority';
  }

  Future<String> _issueMediaAccessToken({
    required String did,
    required String roomId,
    required Uri homeserver,
    required _ParsedMatrixMediaUri parsedMedia,
  }) async {
    final secret = Config().getSecret(_mediaSigningSecretKey);
    if (secret is! String || secret.trim().isEmpty) {
      throw StateError('Matrix media signing secret is not configured');
    }

    final token = JWT(
      {
        'did': did,
        'room_id': roomId,
        'homeserver': _extractAudience(homeserver),
        'server_name': parsedMedia.serverName,
        'media_id': parsedMedia.mediaId,
      },
      subject: did,
      jwtId: const Uuid().v4(),
    );

    return token.sign(
      SecretKey(secret),
      algorithm: JWTAlgorithm.HS256,
      expiresIn: Duration(seconds: _matrixMediaAccessTokenExpirySeconds),
    );
  }

  Future<_MatrixMediaAccessClaims> _verifyMediaAccessToken(String token) async {
    final secret = Config().getSecret(_mediaSigningSecretKey);
    if (secret is! String || secret.trim().isEmpty) {
      throw StateError('Matrix media signing secret is not configured');
    }

    try {
      final jwt = JWT.verify(token, SecretKey(secret));
      final payload = jwt.payload;
      final did = payload['did'];
      final roomId = payload['room_id'];
      final homeserver = payload['homeserver'];
      final serverName = payload['server_name'];
      final mediaId = payload['media_id'];

      if (did is! String ||
          roomId is! String ||
          homeserver is! String ||
          serverName is! String ||
          mediaId is! String) {
        throw MatrixMediaAccessException.badRequest(
          'Invalid matrix media access token',
        );
      }

      if (!_mediaIdPattern.hasMatch(mediaId)) {
        throw MatrixMediaAccessException.badRequest(
          'Invalid matrix media access token',
        );
      }

      final normalizedHomeserver = _normalizeHomeserver(Uri.parse(homeserver));

      return _MatrixMediaAccessClaims(
        did: did,
        roomId: _normalizeRoomId(roomId),
        homeserver: _extractAudience(normalizedHomeserver),
        serverName: serverName,
        mediaId: mediaId,
      );
    } on JWTExpiredException {
      throw MatrixMediaAccessException.forbidden(
        'Matrix media access token expired',
      );
    } on JWTException {
      throw MatrixMediaAccessException.forbidden(
        'Invalid matrix media access token',
      );
    }
  }

  Future<String> _loginForAccessToken({
    required String did,
    required Uri homeserver,
    required http.Client httpClient,
  }) async {
    final loginToken = await issueLoginToken(did: did, homeserver: homeserver);
    final response = await httpClient.post(
      homeserver.resolve('/_matrix/client/v3/login'),
      headers: {HttpHeaders.contentTypeHeader: ContentType.json.mimeType},
      body: jsonEncode({'type': matrixJwtLoginType, 'token': loginToken}),
    );

    if (response.statusCode != HttpStatus.ok) {
      throw _mapMatrixResponse(
        response,
        fallbackMessage: 'Failed to login to Matrix',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw MatrixMediaAccessException.serverError(
        'Invalid Matrix login response',
      );
    }

    final accessToken = decoded['access_token'];
    if (accessToken is! String || accessToken.trim().isEmpty) {
      throw MatrixMediaAccessException.serverError(
        'Missing Matrix access token',
      );
    }

    return accessToken;
  }

  Future<void> _assertRoomMembership({
    required String did,
    required String roomId,
    required Uri homeserver,
    required String accessToken,
    required http.Client httpClient,
  }) async {
    final response = await httpClient.get(
      homeserver.resolve(
        '/_matrix/client/v3/rooms/${Uri.encodeComponent(roomId)}/joined_members',
      ),
      headers: {HttpHeaders.authorizationHeader: 'Bearer $accessToken'},
    );

    if (response.statusCode != HttpStatus.ok) {
      throw _mapMatrixResponse(
        response,
        fallbackMessage: 'Failed to verify room membership',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw MatrixMediaAccessException.serverError(
        'Invalid Matrix membership response',
      );
    }

    final joined = decoded['joined'];
    if (joined is! Map<String, dynamic>) {
      throw MatrixMediaAccessException.serverError(
        'Invalid Matrix membership response',
      );
    }

    final userId = _deriveMatrixUserId(did, homeserver.host);
    if (!joined.containsKey(userId)) {
      throw MatrixMediaAccessException.forbidden(
        'User is not a joined member of the room',
      );
    }
  }

  Future<MatrixDownloadedMedia> _fetchMedia({
    required Uri homeserver,
    required String serverName,
    required String mediaId,
    required String accessToken,
    required http.Client httpClient,
  }) async {
    final response = await httpClient.get(
      homeserver.resolve(
        '/_matrix/client/v1/media/download/${Uri.encodeComponent(serverName)}/${Uri.encodeComponent(mediaId)}',
      ),
      headers: {HttpHeaders.authorizationHeader: 'Bearer $accessToken'},
    );

    if (response.statusCode != HttpStatus.ok) {
      throw _mapMatrixResponse(
        response,
        fallbackMessage: 'Failed to download Matrix media',
      );
    }

    return MatrixDownloadedMedia(
      bytes: Uint8List.fromList(response.bodyBytes),
      contentType: response.headers[HttpHeaders.contentTypeHeader],
    );
  }

  void _enforceRateLimit(String did, String mediaId) {
    final now = DateTime.now().toUtc();
    final key = '$did|$mediaId';
    final attempts = _downloadAttempts.putIfAbsent(key, () => <DateTime>[]);

    attempts.removeWhere(
      (timestamp) => now.difference(timestamp) >= _downloadWindow,
    );

    if (attempts.length >= _maxDownloadsPerMinute) {
      throw MatrixMediaAccessException.rateLimited(
        'Matrix media download rate limit exceeded',
      );
    }

    attempts.add(now);
  }

  MatrixMediaAccessException _mapMatrixResponse(
    http.Response response, {
    required String fallbackMessage,
  }) {
    final retryAfterHeader = response.headers[HttpHeaders.retryAfterHeader];
    final retryAfterSeconds = int.tryParse(retryAfterHeader ?? '');

    return switch (response.statusCode) {
      HttpStatus.forbidden => MatrixMediaAccessException.forbidden(
        fallbackMessage,
      ),
      HttpStatus.notFound => MatrixMediaAccessException.notFound(
        fallbackMessage,
      ),
      HttpStatus.tooManyRequests => MatrixMediaAccessException.rateLimited(
        fallbackMessage,
        retryAfterSeconds: retryAfterSeconds,
      ),
      _ => MatrixMediaAccessException.serverError(fallbackMessage),
    };
  }
}

class MatrixDownloadedMedia {
  MatrixDownloadedMedia({required this.bytes, this.contentType});

  final Uint8List bytes;
  final String? contentType;
}

class MatrixMediaAccessException implements Exception {
  MatrixMediaAccessException._({
    required this.statusCode,
    required this.message,
    this.retryAfterSeconds,
  });

  factory MatrixMediaAccessException.badRequest(String message) =>
      MatrixMediaAccessException._(
        statusCode: HttpStatus.badRequest,
        message: message,
      );

  factory MatrixMediaAccessException.forbidden(String message) =>
      MatrixMediaAccessException._(
        statusCode: HttpStatus.forbidden,
        message: message,
      );

  factory MatrixMediaAccessException.notFound(String message) =>
      MatrixMediaAccessException._(
        statusCode: HttpStatus.notFound,
        message: message,
      );

  factory MatrixMediaAccessException.rateLimited(
    String message, {
    int? retryAfterSeconds,
  }) => MatrixMediaAccessException._(
    statusCode: HttpStatus.tooManyRequests,
    message: message,
    retryAfterSeconds: retryAfterSeconds,
  );

  factory MatrixMediaAccessException.serverError(String message) =>
      MatrixMediaAccessException._(
        statusCode: HttpStatus.internalServerError,
        message: message,
      );

  final int statusCode;
  final String message;
  final int? retryAfterSeconds;
}

class _ParsedMatrixMediaUri {
  _ParsedMatrixMediaUri({required this.serverName, required this.mediaId});

  final String serverName;
  final String mediaId;
}

class _MatrixMediaAccessClaims {
  _MatrixMediaAccessClaims({
    required this.did,
    required this.roomId,
    required this.homeserver,
    required this.serverName,
    required this.mediaId,
  });

  final String did;
  final String roomId;
  final String homeserver;
  final String serverName;
  final String mediaId;
}
