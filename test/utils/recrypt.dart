import 'package:proxy_recrypt/proxy_recrypt.dart';

ReEncryptionKey generateReEncryptionKey(KeyPair keyPair) {
  return Recrypt()
      .generateReEncryptionKey(keyPair.privateKey, keyPair.publicKey);
}

KeyPair generateMemberRecryptKeyPair() {
  return Recrypt().generateKeyPair();
}
