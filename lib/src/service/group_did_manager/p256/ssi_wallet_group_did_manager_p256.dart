import 'package:ssi/ssi.dart';

import '../../../core/did_manager/group_did_manager.dart';
import '../../../core/did_manager/group_did_manager_exception.dart';
import '../../../core/entity/key_reference.dart';
import '../../../core/service/group/group_utils.dart';
import '../../../core/storage/storage.dart';

class SsiWalletGroupDidManagerP256 implements GroupDidManager {
  SsiWalletGroupDidManagerP256({
    required Wallet wallet,
    required Storage storage,
  })  : _wallet = wallet,
        _storage = storage;
  final Storage _storage;
  final Wallet _wallet;

  @override
  Future<DidDocument> createDid(String offerLink) async {
    final keyPair = await _wallet.generateKey(keyType: KeyType.p256);
    final groupDidManager = await _getDidManager(_wallet, keyPair);
    final didDocument = await groupDidManager.getDidDocument();

    final groupId = GroupUtils.generateGroupId(
        offerLink: offerLink, groupDid: didDocument.id);

    await _storage.create(KeyReference(keyId: keyPair.id, entityId: groupId));
    return didDocument;
  }

  @override
  Future<DidManager> get(groupId) async {
    final keyReference = await _storage.findOneById(
        KeyReference.entityName, groupId, KeyReference.fromJson);

    if (keyReference == null) {
      throw GroupDidManagerException(
          message: 'Key reference not found', code: 'key_reference_not_found');
    }

    final keyPair = await _wallet.generateKey(
        keyId: keyReference.keyId, keyType: KeyType.secp256k1);

    return _getDidManager(_wallet, keyPair);
  }

  Future<DidKeyManager> _getDidManager(Wallet wallet, KeyPair keyPair) async {
    final didManager = DidKeyManager(wallet: wallet, store: InMemoryDidStore());
    await didManager.addVerificationMethod(keyPair.id);
    return didManager;
  }

  @override
  Future<void> removeKeys(String groupId) {
    // Key deletion not supported by wallet implementation
    return Future.value();
  }
}
