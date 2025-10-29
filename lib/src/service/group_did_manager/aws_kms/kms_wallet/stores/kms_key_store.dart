import 'dart:typed_data';

class StoredKmsKey {
  StoredKmsKey({required this.id, required this.publicKeyBytes});
  final String id;
  final Uint8List publicKeyBytes;
}

/// An interface for a key-value storage.
abstract interface class KMSKeyStore {
  /// Stores a value associated with the given key.
  Future<void> set(String id, StoredKmsKey value);

  /// Retrieves the value associated with the given key.
  /// Returns null if the key does not exist or stores a seed.
  Future<StoredKmsKey?> get(String key);

  /// Checks if a key pair (not a seed) exists in the store for the given key.
  Future<bool> contains(String key);
}
