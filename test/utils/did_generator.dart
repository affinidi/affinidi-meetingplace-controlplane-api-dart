import 'dart:typed_data';
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:bs58/bs58.dart';

class DidGenerator {
  static generateDidKey() async {
    // Generate a random 32-byte seed
    final seed = Uint8List.fromList(
        List.generate(32, (_) => (DateTime.now().microsecond % 256)));

    // Generate the key pair
    final keyData = await ED25519_HD_KEY.getMasterKeyFromSeed(seed);
    final publicKey = keyData.key.sublist(0, 32);

    // Prefix for Ed25519 public key (0xed, 0x01) according to multicodec
    final prefixedKey = Uint8List.fromList([0xed, 0x01] + publicKey);

    // Encode with base58btc
    return 'did:key:z${base58.encode(prefixedKey)}';
  }
}
