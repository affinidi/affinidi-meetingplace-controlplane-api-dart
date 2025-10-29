import 'dart:convert';
import 'dart:io';
import 'package:api_meetingplace_dart_oss/src/adapter/did_document_manager/aws_ssm_did_document_manager.dart';
import 'package:api_meetingplace_dart_oss/src/adapter/group_did_manager/ssi_wallet_impl.dart';
import 'package:api_meetingplace_dart_oss/src/adapter/logger/basic_logger.dart';
import 'package:api_meetingplace_dart_oss/src/adapter/push_notification_provider/sns.dart';
import 'package:api_meetingplace_dart_oss/src/adapter/secret_manager/aws_secret_manager.dart';
import 'package:api_meetingplace_dart_oss/src/adapter/storage/redis.dart';
import 'package:api_meetingplace_dart_oss/src/api/application_facade.dart';
import 'package:api_meetingplace_dart_oss/src/core/config/config.dart';
import 'package:api_meetingplace_dart_oss/src/core/config/env_config.dart';
import 'package:api_meetingplace_dart_oss/src/adapter/secret_manager/secret_manager.dart';
import 'package:api_meetingplace_dart_oss/src/core/config/server_config.dart';
import 'package:api_meetingplace_dart_oss/src/server/middleware/request_logger.dart';
import 'package:api_meetingplace_dart_oss/src/server/middleware/response_header.dart';
import 'package:api_meetingplace_dart_oss/src/server/router.dart';
import 'package:api_meetingplace_dart_oss/src/core/did_resolver/did_resolver.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:ssi/ssi.dart';

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;
  Config config = await Config().loadConfig(getEnv('ENV'));

  final secretManager =
      SecretManager.withProvider(await AWSSecretManager.init());

  config.registerSecret(
    'didcommauth',
    jsonDecode(await secretManager.getSecret(getEnv('DIDCOMM_AUTH_SECRET'))),
  );

  config.registerSecret(
    'hashSecret',
    jsonDecode(await secretManager.getSecret(getEnv('HASH_SECRET'))),
  );

  // Environment dependent configuration
  final logger = BasicLogger();
  final storage = await Redis.init(logger: logger);
  final serverConfig = ServerConfig(
    secretManager: secretManager,
    storage: storage,
    groupDidManager: SsiWalletGroupDidManagerImpl(
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
