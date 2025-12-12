import 'package:ssi/ssi.dart';

import '../../../core/did_manager/group_did_manager.dart';
import '../../../core/did_manager/group_did_manager_exception.dart';
import '../../../core/entity/key_reference.dart';
import '../../../core/service/group/group_utils.dart';
import '../../../core/storage/storage.dart';
import 'bip32.dart';

class SsiWalletGroupDidManagerBip32 implements GroupDidManager {
  SsiWalletGroupDidManagerBip32({
    required Wallet wallet,
    required Storage storage,
  }) : _wallet = wallet,
       _storage = storage;
  final Storage _storage;
  final Wallet _wallet;

  @override
  Future<DidDocument> createDid(String offerLink) async {
    final accountIndex = await _storage.findOneById<Bip32>(
      Bip32.entityName,
      'accountIndex',
      Bip32.fromJson,
    );

    final nextAccountIndex = accountIndex != null
        ? int.parse(accountIndex.accountingIndex) + 1
        : 1;

    final derivationPath = "m/44'/60'/0'/0'/$nextAccountIndex'";

    final keyPair = await _wallet.generateKey(
      keyType: KeyType.secp256k1,
      keyId: derivationPath,
    );
    final groupDidManager = await _getDidManager(_wallet, keyPair);
    final didDocument = await groupDidManager.getDidDocument();

    final groupId = GroupUtils.generateGroupId(
      offerLink: offerLink,
      groupDid: didDocument.id,
    );

    await _storage.create(KeyReference(keyId: keyPair.id, entityId: groupId));
    if (accountIndex == null) {
      await _storage.create(
        Bip32(accountingIndex: nextAccountIndex.toString()),
      );
    } else {
      accountIndex.accountingIndex = nextAccountIndex.toString();
      await _storage.update(accountIndex);
    }

    return didDocument;
  }

  @override
  Future<DidManager> get(groupId) async {
    final keyReference = await _storage.findOneById(
      KeyReference.entityName,
      groupId,
      KeyReference.fromJson,
    );

    if (keyReference == null) {
      throw GroupDidManagerException(
        message: 'Key reference not found',
        code: 'key_reference_not_found',
      );
    }

    final keyPair = await _wallet.generateKey(
      keyId: keyReference.keyId,
      keyType: KeyType.secp256k1,
    );
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
