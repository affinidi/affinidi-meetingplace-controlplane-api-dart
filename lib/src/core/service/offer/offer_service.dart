import 'dart:async';
import '../../config/config.dart';
import '../../logger/logger.dart';
import '../../storage/exception/already_exists_exception.dart';
import '../../storage/exception/conditional_update_failed_exception.dart';
import 'deregister_offer_input.dart';
import 'register_offer_input.dart';
import '../../storage/storage.dart';
import '../../entity/offer.dart';
import '../device_mapping/device_token_mapping_service.dart';
import '../../../utils/hash.dart';
import '../../../utils/mnemonic.dart';
import '../../../utils/ttl.dart';
import 'package:uuid/uuid.dart';

enum OfferAccessType { claim, query, queryNoLimits }

class OfferCreationFailed implements Exception {}

class OfferNotFound implements Exception {
  OfferNotFound({required this.mnemonic});

  final String mnemonic;
}

class OfferLinkMismatch implements Exception {}

class NotAuthorizedException implements Exception {}

class OfferExpired implements Exception {
  OfferExpired({required this.mnemonic});

  final String mnemonic;
}

class OfferExists implements Exception {}

class AccessTypeNotSupported implements Exception {}

class OfferQueryLimitExceeded implements Exception {}

class OfferUpdateFailed implements Exception {
  OfferUpdateFailed(this.message);
  final Object message;
}

class InvalidOfferInput implements Exception {
  InvalidOfferInput(this.message);
  final String message;
}

class OfferService {
  OfferService({
    required Storage storage,
    required DeviceTokenMappingService deviceTokenMappingService,
    required Logger logger,
  })  : _storage = storage,
        _deviceTokenMappingService = deviceTokenMappingService,
        _logger = logger;

  final Storage _storage;
  final DeviceTokenMappingService _deviceTokenMappingService;
  final Logger _logger;

  Future<Offer> registerOffer(RegisterOfferInput input, String authDid) async {
    final offerLimits = _getOfferLimits(input.maximumUsage);
    _logger.info('Offer limits:');
    _logger.info('- [maximum claims]: ${offerLimits['maximumClaims']}');
    _logger.info('- [maximum queries]: ${offerLimits['maximumQueries']}');

    final validUntil = _getValidUntil(input.validUntil);
    _logger.info('Offer valid until: $validUntil');

    final deviceTokenMapping =
        await _deviceTokenMappingService.getDeviceTokenMapping(
      devicePlatform: input.platformType,
      deviceToken: input.deviceToken,
    );

    final mnemonic = _getMnemonic(input.customPhrase);
    _logger.info('using mnemonic for offer registration: $mnemonic');

    DateTime? ttl;
    if (validUntil != null) {
      try {
        ttl = addMinutesToDate(
          DateTime.parse(validUntil).toUtc(),
          Config().get('offer')['ttlInMinutesAfterValidUntil'],
        );
      } on FormatException {
        _logger.error('Invalid date format for validUntil: $validUntil');
        throw InvalidOfferInput('Invalid date format for validUntil');
      }
    }
    _logger.info('ttl for offer: $ttl');

    final offer = Offer(
      id: _generateId(mnemonic),
      name: input.offerName,
      description: input.offerDescription,
      offerType: input.offerType,
      didcommMessage: input.didcommMessage,
      vcard: input.vcard,
      platformType: deviceTokenMapping.platformType,
      platformEndpointArn: deviceTokenMapping.platformEndpointArn,
      maximumQueries: offerLimits['maximumQueries'],
      maximumClaims: offerLimits['maximumClaims'],
      validUntil: validUntil,
      contactAttributes: input.contactAttributes,
      mediatorDid: input.mediatorDid,
      mediatorEndpoint: input.mediatorEndpoint,
      mediatorWSSEndpoint: input.mediatorWSSEndpoint,
      mnemonic: mnemonic,
      offerLink: _generateOfferLink(),
      metadata: input.metadata,
      createdBy: authDid,
      ttl: ttl,
    );

    try {
      return await _storage.create(offer);
    } on AlreadyExists {
      _logger.info('Offer already exists');
      throw OfferExists();
    } catch (e, stackTrace) {
      _logger.error('Error registering offer $e',
          error: e, stackTrace: stackTrace);
      throw OfferCreationFailed();
    }
  }

  Future<void> deregisterOffer(
    DeregisterOfferInput input,
    String authDid,
  ) async {
    final offerId = _generateId(input.mnemonic);
    final offer = await _storage.findOneById(
      Offer.entityName,
      offerId,
      Offer.fromJson,
    );

    if (offer == null) {
      _logger.info('Offer not found');
      throw OfferNotFound(mnemonic: input.mnemonic);
    }

    if (offer.offerLink != input.offerLink) {
      _logger.info('Offer link does not match');
      throw OfferLinkMismatch();
    }

    if (offer.createdBy != authDid) {
      _logger.info('Authenticated did not authorized to deregister offer');
      throw NotAuthorizedException();
    }

    return _storage.delete(Offer.entityName, offer.id);
  }

  Future<Offer> updateOffer(Offer offer) {
    return _storage.update(offer);
  }

  Future<Offer?> queryOffer(OfferAccessType accessType, String offerId) async {
    Offer? offer;

    try {
      _logger.info('Query offer by id: $offerId and access type: $accessType');
      offer = await _storage.updateWithCondition<Offer>(
        Offer.entityName,
        offerId,
        Offer.fromJson,
        updateFn: _getUpdateActionByAccessType(accessType),
        conditionFn: _getUpdateConditionByAccessType(accessType),
      );
    } on ConditionalUpdateFailed {
      _logger.info('Conditional offer update failed.');
      throw OfferQueryLimitExceeded();
    } catch (e, stackTrace) {
      _logger.error('Offer update failed: $e',
          error: e, stackTrace: stackTrace);
      throw OfferUpdateFailed(e);
    }

    if (offer == null) {
      return null;
    }

    if (_hasOfferExpired(offer, OfferAccessType.claim)) {
      throw OfferExpired(mnemonic: offer.mnemonic);
    }

    _logger.info('Remaining offer limits:');
    _logger.info('- [claims]: ${offer.claimCount} / ${offer.maximumClaims}');
    _logger.info('- [queries]: ${offer.queryCount} / ${offer.maximumQueries}');

    return offer;
  }

  Future<Offer?> queryOfferByMnemonic(
    OfferAccessType acceessType,
    String mnemonic,
  ) async {
    final offerId = _generateId(mnemonic);
    return queryOffer(acceessType, offerId);
  }

  Future<bool> isMnemonicInUse(String mnemonic) async {
    final cleanMnemonic = cleanUpCustomPhrase(mnemonic).join(
      Config().get('offer')['mnemonicWordSeparator'],
    );

    final offerId = _generateId(cleanMnemonic);
    final offer =
        await _storage.findOneById(Offer.entityName, offerId, Offer.fromJson);

    return offer != null;
  }

  bool _hasOfferExpired(Offer offer, OfferAccessType accessType) {
    if (offer.validUntil == null) {
      return false;
    }

    try {
      if (DateTime.parse(offer.validUntil!).millisecondsSinceEpoch >
          DateTime.now().millisecondsSinceEpoch) {
        return false;
      }
    } on FormatException {
      _logger.error(
        'Invalid date format in stored offer: ${offer.validUntil}',
      );
      return true;
    }

    _logger.info('Offer date has expired: ${offer.validUntil}');
    if (accessType == OfferAccessType.queryNoLimits) {
      _logger.info('Ignoring - return anyway due to QueryNoLimits access type');
      return false;
    }

    return true;
  }

  String _generateOfferLink() => Uuid().v4();

  String _getMnemonic(String? customPhrase) {
    return (customPhrase == null || customPhrase.isEmpty
            ? getShortPhrase(Config().get('offer')['mnemonicWordCount'])
            : cleanUpCustomPhrase(customPhrase))
        .join(Config().get('offer')['mnemonicWordSeparator']);
  }

  Map<String, dynamic> _getOfferLimits(int? maximumUsageInput) {
    if (maximumUsageInput == null || maximumUsageInput == 0) {
      return {
        'maximumClaims': null,
        'maximumQueries': null,
      };
    }

    return {
      'maximumClaims': maximumUsageInput,
      'maximumQueries': maximumUsageInput,
    };
  }

  String? _getValidUntil(String? validUntilInput) {
    if (validUntilInput == null || validUntilInput.isEmpty) {
      return null;
    }

    return validUntilInput;
  }

  String _generateId(String mnemonic) {
    return generateHashedId(mnemonic, Config().hashSecret());
  }

  bool Function(Offer) _getUpdateConditionByAccessType(
    OfferAccessType accessType,
  ) {
    if (accessType == OfferAccessType.query) {
      return (Offer offer) =>
          (offer.maximumQueries == null || offer.maximumClaims == null) ||
          (offer.queryCount < offer.maximumQueries! &&
              offer.claimCount < offer.maximumClaims!);
    }

    if (accessType == OfferAccessType.queryNoLimits) {
      return (Offer offer) => true;
    }

    if (accessType == OfferAccessType.claim) {
      return (Offer offer) =>
          offer.maximumClaims == null ||
          offer.claimCount < offer.maximumClaims!;
    }

    throw AccessTypeNotSupported();
  }

  Offer Function(Offer) _getUpdateActionByAccessType(
    OfferAccessType accessType,
  ) {
    if (accessType == OfferAccessType.query) {
      return (Offer offer) => offer.increaseQueryCount();
    }

    if (accessType == OfferAccessType.claim) {
      return (Offer offer) => offer.increaseClaimCount();
    }

    if (accessType == OfferAccessType.queryNoLimits) {
      return (Offer offer) => offer;
    }

    throw AccessTypeNotSupported();
  }
}
