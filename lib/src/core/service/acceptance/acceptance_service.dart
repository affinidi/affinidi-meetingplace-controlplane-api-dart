import '../../config/config.dart';
import '../../logger/logger.dart';
import 'accept_offer_input.dart';
import 'finalise_acceptance_input.dart';
import 'query_acceptance_input.dart';
import '../notification/notify_finalise_acceptance_input.dart';
import '../../storage/storage.dart';
import '../../../utils/hash.dart';
import '../../entity/offer.dart';
import '../offer/offer_service.dart';
import '../../entity/acceptance.dart';
import '../device_mapping/device_token_mapping_service.dart';
import '../notification/notification_service.dart';

class AcceptanceNotFound implements Exception {
  AcceptanceNotFound(this.message);
  final String message;
}

class AcceptanceService {
  AcceptanceService({
    required Storage storage,
    required OfferService offerService,
    required DeviceTokenMappingService deviceTokenMappingService,
    required NotificationService notificationService,
    required Logger logger,
  }) : _storage = storage,
       _offerService = offerService,
       _deviceTokenMappingService = deviceTokenMappingService,
       _notificationService = notificationService,
       _logger = logger;

  final Storage _storage;
  final OfferService _offerService;
  final DeviceTokenMappingService _deviceTokenMappingService;
  final NotificationService _notificationService;
  final Logger _logger;

  Future<Offer> acceptOffer(AcceptOfferInput input, String authDid) async {
    final deviceTokenMapping = await _deviceTokenMappingService
        .getDeviceTokenMapping(
          devicePlatform: input.platformType,
          deviceToken: input.deviceToken,
        );

    final offer = await _offerService.queryOfferByMnemonic(
      OfferAccessType.claim,
      input.mnemonic,
    );

    if (offer == null) {
      throw OfferNotFound(mnemonic: input.mnemonic);
    }

    final acceptanceId = _generateId(
      mnemonic: input.mnemonic,
      did: input.acceptOfferAsDid,
      offerLink: offer.offerLink,
    );

    final acceptance = Acceptance(
      id: acceptanceId,
      did: input.acceptOfferAsDid,
      offerLink: offer.offerLink,
      vcard: input.vcard,
      status: Status.created,
      platformEndpointArn: deviceTokenMapping.platformEndpointArn,
      platformType: deviceTokenMapping.platformType,
      mediatorDid: offer.mediatorDid,
      mediatorEndpoint: offer.mediatorEndpoint,
      mediatorWSSEndpoint: offer.mediatorWSSEndpoint,
      createdBy: authDid,
    );

    await _storage.create(acceptance);
    return offer;
  }

  Future<String?> finaliseAcceptance(
    FinaliseAcceptanceInput input,
    String authDid,
  ) async {
    final acceptance = await queryAcceptance(
      QueryAcceptanceInput(
        mnemonic: input.mnemonic,
        didUsedForAcceptance: input.didUsedForAcceptance,
        offerLink: input.offerLink,
      ),
    );

    final notificationChannelId = await _notificationService
        .notifyFinaliseAcceptance(
          NotifyFinaliseAcceptanceInput(
            acceptance: acceptance,
            didUsedForAcceptance: input.didUsedForAcceptance,
            theirDid: input.theirDid,
            authDid: authDid,
            deviceToken: input.deviceToken,
            platformType: input.platformType,
          ),
        );

    return notificationChannelId;
  }

  Future<Acceptance> queryAcceptance(QueryAcceptanceInput input) async {
    final id = _generateId(
      mnemonic: input.mnemonic,
      did: input.didUsedForAcceptance,
      offerLink: input.offerLink,
    );

    final acceptance = await _storage.findOneById(
      Acceptance.entityName,
      id,
      Acceptance.fromJson,
    );

    if (acceptance == null) {
      _logger.info('Acceptance record not found');
      throw AcceptanceNotFound('Acceptance does not exist');
    }

    _logger.info('Acceptance record found');
    return acceptance;
  }

  String _generateId({
    required String mnemonic,
    required String did,
    required String offerLink,
  }) {
    final value = '${mnemonic}_${did}_$offerLink';
    return generateHashedId(value, Config().hashSecret());
  }
}
