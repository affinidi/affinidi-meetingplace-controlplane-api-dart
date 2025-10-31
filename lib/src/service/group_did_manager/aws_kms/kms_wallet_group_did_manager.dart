import 'package:ssi/ssi.dart' hide Wallet;

import '../../../core/did_manager/group_did_manager.dart';
import '../../../core/entity/key_reference.dart';
import 'kms_wallet/kms_wallet_exception.dart';
import '../../../core/service/group/group_utils.dart';
import '../../../core/storage/storage.dart';
import 'kms_wallet/kms_wallet.dart';

class KMSWalletGroupDidManager implements GroupDidManager {
  KMSWalletGroupDidManager({
    required KmsWallet wallet,
    required Storage storage,
  })  : _wallet = wallet,
        _storage = storage;
  final Storage _storage;
  final KmsWallet _wallet;

  @override
  Future<DidDocument> createDid(String offerLink) async {
    // Generate signing key for DIDDocument generation, signing and verifying
    final signingKeyPair = await _wallet.generateKey(
      keyType: KeyType.p256,
      keyUsage: KeyUsage.signingVerify,
    );

    // Generate key agreement key pair to support ECDH shared secret
    final keyAgreementKeyPair = await _wallet.generateKey(
      keyType: KeyType.p256,
      keyUsage: KeyUsage.keyAgreement,
    );

    final groupDidManager = await _getDidManager(
      wallet: _wallet,
      signingKeyPairId: signingKeyPair.id,
      keyAgreementKeyPairId: keyAgreementKeyPair.id,
    );

    final didDocument = await groupDidManager.getDidDocument();
    final groupId = GroupUtils.generateGroupId(
      offerLink: offerLink,
      groupDid: didDocument.id,
    );

    await Future.wait([
      _storeKeyReference(
        keyPair: signingKeyPair,
        keyUsage: KeyUsage.signingVerify,
        entityId: groupId,
      ),
      _storeKeyReference(
        keyPair: keyAgreementKeyPair,
        keyUsage: KeyUsage.keyAgreement,
        entityId: groupId,
      ),
    ]);

    return didDocument;
  }

  @override
  Future<void> removeKeys(String groupId) async {
    final signingKeyReference = await _getKeyReference(
        keyUsage: KeyUsage.signingVerify, groupId: groupId);

    final keyAgreementReference = await _getKeyReference(
        keyUsage: KeyUsage.keyAgreement, groupId: groupId);

    await _wallet.deleteKeyPair(signingKeyReference.keyId);
    await _removeKeyReference(signingKeyReference.keyId);

    await _wallet.deleteKeyPair(keyAgreementReference.keyId);
    await _removeKeyReference(keyAgreementReference.keyId);
  }

  @override
  Future<DidManager> get(groupId) async {
    final signingKeyReference = await _getKeyReference(
        keyUsage: KeyUsage.signingVerify, groupId: groupId);

    final keyAgreementReference = await _getKeyReference(
        keyUsage: KeyUsage.keyAgreement, groupId: groupId);

    final groupDidManager = await _getDidManager(
      wallet: _wallet,
      signingKeyPairId: signingKeyReference.keyId,
      keyAgreementKeyPairId: keyAgreementReference.keyId,
    );

    return groupDidManager;
  }

  Future<DidPeerManager> _getDidManager({
    required KmsWallet wallet,
    required String signingKeyPairId,
    required String keyAgreementKeyPairId,
  }) async {
    final groupDidManager =
        DidPeerManager(wallet: wallet, store: InMemoryDidStore());

    await groupDidManager.init();
    await groupDidManager
        .addVerificationMethod(signingKeyPairId, relationships: {
      VerificationRelationship.authentication,
      VerificationRelationship.assertionMethod,
      VerificationRelationship.capabilityInvocation,
      VerificationRelationship.capabilityDelegation,
    });
    await groupDidManager.addVerificationMethod(keyAgreementKeyPairId,
        relationships: {VerificationRelationship.keyAgreement});

    return groupDidManager;
  }

  Future<void> _storeKeyReference({
    required KeyPair keyPair,
    required KeyUsage keyUsage,
    required String entityId,
  }) async {
    await _storage.create(KeyReference(
        keyId: keyPair.id, entityId: '$entityId-${keyUsage.name}'));
  }

  Future<void> _removeKeyReference(String keyId) async {
    await _storage.delete(KeyReference.entityName, keyId);
  }

  Future<KeyReference> _getKeyReference({
    required KeyUsage keyUsage,
    required String groupId,
  }) async {
    final keyReferenceId = '$groupId-${keyUsage.name}';
    final result = await _storage.findOneById(
        KeyReference.entityName, keyReferenceId, KeyReference.fromJson);

    if (result == null) {
      throw KmsWalletException.keyReferenceNotFound(
          keyReferenceId: keyReferenceId);
    }

    return result;
  }
}
