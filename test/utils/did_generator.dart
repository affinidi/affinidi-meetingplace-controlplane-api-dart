import 'package:ssi/ssi.dart';

class DidGenerator {
  static generateDidKey(Wallet wallet) async {
    final keyPair = await wallet.generateKey();

    final DidManager didManager = DidKeyManager(
      store: InMemoryDidStore(),
      wallet: wallet,
    );
    await didManager.addVerificationMethod(keyPair.id);
    final didDoc = await didManager.getDidDocument();

    return didDoc.id;
  }
}
