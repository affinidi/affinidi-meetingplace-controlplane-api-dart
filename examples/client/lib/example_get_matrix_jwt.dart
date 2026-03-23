import 'dart:io';

import 'package:dotenv/dotenv.dart';

import 'client_helper.dart';

Future<void> main() async {
  final env = DotEnv(includePlatformEnvironment: true)..load(['.env', '.env']);

  final apiEndpoint = env['API_ENDPOINT'] ?? 'http://localhost:3000';
  final controlPlaneDid = env['CONTROL_PLANE_DID'] ?? 'did:localhost:3000';
  final homeserver = env['MATRIX_HOMESERVER'] ?? 'matrix.example.com';

  final helper = ClientHelper(
    apiEndpoint: apiEndpoint,
    controlPlaneDid: controlPlaneDid,
  );

  final (didManager, keyPair) = await helper.createDidManagerWithKeyPair();
  final didDoc = await didManager.getDidDocument();

  // Authenticate once, then reuse the access token to fetch the Matrix JWT.
  final accessToken = await helper.authenticate(
    didManager: didManager,
    keyPair: keyPair,
  );

  final jwt = await helper.getMatrixRegistrationCredentialJwt(
    didManager: didManager,
    keyPair: keyPair,
    homeserver: homeserver,
    accessToken: accessToken,
  );

  stdout.writeln('DID: ${didDoc.id}');
  stdout.writeln('Homeserver: $homeserver');
  stdout.writeln('Matrix registration credential (JWT):');
  stdout.writeln(jwt);
}
