import 'package:ssi/ssi.dart';

import '../../adapter/secret_manager/secret_manager.dart';
import '../logger/logger.dart';
import '../service/device_notification/push_notification_provider.dart';
import '../../adapter/storage/storage.dart';
import '../web_manager/did_document_manager.dart';
import '../did_manager/group_did_manager.dart';

class ServerConfig {
  ServerConfig({
    required this.storage,
    required this.secretManager,
    required this.groupDidManager,
    required this.pushNotificationProvider,
    required this.didDocumentManager,
    required this.didResolver,
    required this.logger,
  });

  final IStorage storage;
  final SecretManager secretManager;
  final GroupDidManager groupDidManager;
  final PushNotificationProvider pushNotificationProvider;
  final DidDocumentManager didDocumentManager;
  final DidResolver didResolver;
  final Logger logger;
}
