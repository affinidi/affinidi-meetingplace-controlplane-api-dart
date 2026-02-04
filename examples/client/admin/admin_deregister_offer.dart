import 'dart:io';
import 'dart:typed_data';
import 'package:args/args.dart';

import 'package:convert/convert.dart';
import 'package:dotenv/dotenv.dart';
import 'package:meeting_place_control_plane_api_client_examples/client_helper.dart';
import 'package:ssi/ssi.dart';

Future<void> main(List<String> arguments) async {
  final env = DotEnv()..load(['.env']);

  final apiEndpoint = env['API_ENDPOINT'];
  final controlPlaneDid = env['CONTROL_PLANE_DID'];

  // Note: Seed used here for example purposes only.
  // In production, use secure key management.
  final walletSeed = env['ADMIN_WALLET_SEED'];

  if (apiEndpoint == null ||
      apiEndpoint.isEmpty ||
      controlPlaneDid == null ||
      controlPlaneDid.isEmpty ||
      walletSeed == null ||
      walletSeed.isEmpty) {
    print(
      'Please ensure that API_ENDPOINT, CONTROL_PLANE_DID, and '
      'ADMIN_WALLET_SEED are set in the .env file.',
    );
    exit(1);
  }

  final helper = ClientHelper(
    apiEndpoint: apiEndpoint,
    controlPlaneDid: controlPlaneDid,
  );

  // Create a wallet from the mnemonic
  final wallet =
      Bip32Wallet.fromSeed(Uint8List.fromList(hex.decode(walletSeed)));
  print('✓ Wallet created from seed');

  // Derived key pair matches the admin DID in the whitelist from .env
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
