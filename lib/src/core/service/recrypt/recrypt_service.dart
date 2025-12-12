import 'package:proxy_recrypt/proxy_recrypt.dart';

class RecryptService {
  RecryptService._(this._recrypt);

  static RecryptService? _instance;

  final Recrypt _recrypt;

  static RecryptService getInstance() {
    _instance ??= RecryptService._(Recrypt());
    return _instance!;
  }

  Capsule reEncryptCapsule(
    String capsuleBase64, {
    required String reencryptionKeyBase64,
  }) {
    final reEncryptionKey = ReEncryptionKey.fromBase64(reencryptionKeyBase64);

    return _recrypt.reEncrypt(
      Capsule.fromBase64(capsuleBase64),
      reEncryptionKey,
    );
  }
}
