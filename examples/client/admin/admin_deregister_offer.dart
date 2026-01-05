import 'dart:io';
import 'dart:typed_data';
import 'package:args/args.dart';

import 'package:convert/convert.dart';
import 'package:dotenv/dotenv.dart';
import 'package:meeting_place_control_plane_api_client_examples/client_helper.dart';
import 'package:ssi/ssi.dart';

Future<void> main(List<String> arguments) async {
  final env = DotEnv()..load(['.env']);

  final apiEndpoint = env['API_ENDPOINT'] ?? 'http://localhost:3000';
  final controlPlaneDid = env['CONTROL_PLANE_DID'] ?? 'did:localhost:3000';

  final walletSeed =
      env['WALLET_SEED'] ?? (throw Exception('WALLET_SEED not set'));

  print('=== Client Example ===\n');

  final helper = ClientHelper(
    apiEndpoint: apiEndpoint,
    controlPlaneDid: controlPlaneDid,
  );

  // Create a wallet from the mnemonic
  final wallet =
      Bip32Wallet.fromSeed(Uint8List.fromList(hex.decode(walletSeed)));
  print('✓ Wallet created from seed');

  final adminKeyPair = await wallet.generateKey(keyId: "m/44'/60'/0'/0/0");
  final adminDidManager = await helper.createDidManagerFromKeyPair(
    wallet: wallet,
    keyPair: adminKeyPair,
  );

  final adminDidDoc = await adminDidManager.getDidDocument();
  print('✓ DID Manager created -> ${adminDidDoc.id}');

  final adminToken = await helper.authenticate(
    didManager: adminDidManager,
    keyPair: adminKeyPair,
    signatureScheme: SignatureScheme.ecdsa_secp256k1_sha256,
  );
  print('✓ Authenticated');

  final adminDio = helper.getDioWithAuth(adminToken);

  final parser = ArgParser()..addOption('mnemonic');
  final args = parser.parse(arguments);
  final mnemonic = args['mnemonic'] ??
      (throw Exception('Please provide --mnemonic argument'));

  try {
    final registerResponse = await adminDio.post(
      '$apiEndpoint/v1/admin/deregister-offer',
      data: {'mnemonic': mnemonic},
    );
    if (registerResponse.statusCode == 200) {
      print('✓ Offer with mnemonic $mnemonic deregistered');
    } else {
      print(
        '✗ Failed to deregister offer: ${registerResponse.statusCode} '
        '${registerResponse.data}',
      );
    }
  } catch (e) {
    print('✗ Error during deregistering offer: $e');
  }

  exit(0);
}
