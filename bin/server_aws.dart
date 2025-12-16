import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:ssi/ssi.dart';

import 'package:meeting_place_control_plane_api/meeting_place_control_plane_api.dart';

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;
  Config config = await Config().loadConfig(getEnv('ENV'));

  final secretManager = SecretManager.withProvider(
    await AWSSecretManager.init(),
  );

  _registerSecrets(secretManager: secretManager, config: config);

  // Environment dependent configuration
  final logger = ProdLogger();
  final storage = await DynamoDBStorage.init(logger: logger);
  final serverConfig = ServerConfig(
    secretManager: secretManager,
    storage: storage,
    groupDidManager: SsiWalletGroupDidManagerP256(
      wallet: PersistentWallet(InMemoryKeyStore()),
      storage: storage,
    ),
    pushNotificationProvider: await SNSProvider.init(logger: logger),
    didDocumentManager: await AwsSsmDidDocumentManager.init(),
    didResolver: CachedDidResolver(),
    logger: logger,
  );

  final controlPlane = ApplicationFacade.init(serverConfig);

  final router = createRouter(controlPlane);

  final handler = Pipeline()
      .addMiddleware(requestLoggerMiddleware(logger))
      .addMiddleware(defaultContentType('application/json'))
      .addHandler(router.call);

  final port = int.parse(getEnv('SERVER_PORT'));
  final server = await serve(handler, ip, port);

  // ignore: avoid_print
  print('Server listening on port ${server.port}');
}

void _registerSecrets({
  required SecretManager secretManager,
  required Config config,
}) async {
  config.registerSecret(
    'didcommauth',
    jsonDecode(await secretManager.getSecret(getEnv('DIDCOMM_AUTH_SECRET'))),
  );

  config.registerSecret(
    'hashSecret',
    jsonDecode(await secretManager.getSecret(getEnv('HASH_SECRET'))),
  );
}
