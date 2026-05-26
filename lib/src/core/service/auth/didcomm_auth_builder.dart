import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import '../../config/config.dart';
import '../../logger/logger.dart';
import '../../storage/storage.dart';
import 'didcomm_auth.dart';

class DIDCommAuthBuilder {
  DIDCommAuthBuilder({required Logger logger, Storage? storage})
    : _logger = logger,
      _storage = storage;

  final Logger _logger;
  final Storage? _storage;

  Future<DIDCommAuth> build() async {
    final didcommauth = Config().getSecret('didcommauth');

    if (didcommauth == null) {
      throw Exception('Secret not found');
    }

    final ed25519Jwk = _getEd25519JwkFromJwks(didcommauth);
    final privateKey = JWTKey.fromJWK(ed25519Jwk['privateKeyJwk']);

    final publicKeyJwk = Map<String, dynamic>.from(ed25519Jwk['privateKeyJwk']);
    publicKeyJwk.remove('d');

    final publicKey = JWTKey.fromJWK(publicKeyJwk);

    return DIDCommAuth(
      privateKey: privateKey,
      publicKey: publicKey,
      jwk: didcommauth,
      logger: _logger,
      storage: _storage,
    );
  }

  _getEd25519JwkFromJwks(List<dynamic> jwks) {
    return jwks.firstWhere((doc) => doc['privateKeyJwk']['crv'] == 'Ed25519');
  }
}
