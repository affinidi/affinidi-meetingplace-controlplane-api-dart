import 'dart:typed_data';

import 'package:convert/convert.dart';

import '../../../storage/storage.dart';
import 'kms_key.dart';
import 'kms_key_store.dart';

class KMSKeyStoreImpl implements KMSKeyStore {
  KMSKeyStoreImpl(IStorage storage) : _storage = storage;
  final IStorage _storage;

  @override
  Future<bool> contains(String key) async {
    final result =
        await _storage.findOneById(KmsKey.entityName, key, KmsKey.fromJson);
    return result != null;
  }

  @override
  Future<StoredKmsKey?> get(String key) async {
    final result =
        await _storage.findOneById(KmsKey.entityName, key, KmsKey.fromJson);

    return result != null
        ? StoredKmsKey(
            id: result.keyId,
            publicKeyBytes: Uint8List.fromList(hex.decode(result.publicKey)))
        : null;
  }

  @override
  Future<void> set(String id, StoredKmsKey value) async {
    await _storage.create(
        KmsKey(keyId: value.id, publicKey: hex.encode((value.publicKeyBytes))));
  }
}
