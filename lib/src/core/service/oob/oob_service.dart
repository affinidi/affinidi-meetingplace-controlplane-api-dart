import '../../config/config.dart';
import '../../entity/oob.dart';
import '../../logger/logger.dart';
import 'create_oob_input.dart';
import '../../storage/storage.dart';
import '../../../utils/ttl.dart';
import 'package:uuid/uuid.dart';

class OobService {
  OobService({required Storage storage, required Logger logger})
      : _storage = storage,
        _logger = logger;

  final Storage _storage;
  final Logger _logger;

  Future<Oob> create(CreateOobInput input) {
    final oobId = _generateId();
    _logger.info('generated oob id: $oobId');

    final ttl = addMinutesToDate(
      DateTime.now().toUtc(),
      Config().get('oob')['ttlInMinutes'],
    );
    _logger.info('ttl for oob: $ttl');

    return _storage.create(Oob(
      oobId: oobId,
      didcommMessage: input.didcommMessage,
      mediatorDid: input.mediatorDid,
      mediatorEndpoint: input.mediatorEndpoint,
      mediatorWSSEndpoint: input.mediatorWSSEndpoint,
      ttl: ttl,
    ));
  }

  Future<Oob?> get(String id) {
    return _storage.findOneById(Oob.entityName, id, Oob.fromJson);
  }

  String _generateId() {
    return Uuid().v4();
  }
}
