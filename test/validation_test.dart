import 'package:meeting_place_control_plane_api/src/api/accept_offer/request_model.dart';
import 'package:meeting_place_control_plane_api/src/api/accept_offer/request_validator.dart';
import 'package:meeting_place_control_plane_api/src/api/accept_offer_group/request_model.dart';
import 'package:meeting_place_control_plane_api/src/api/accept_offer_group/request_validator.dart';
import 'package:meeting_place_control_plane_api/src/api/check_offer_phrase/request_model.dart';
import 'package:meeting_place_control_plane_api/src/api/check_offer_phrase/request_validator.dart';
import 'package:meeting_place_control_plane_api/src/api/delete_pending_notifications/request_model.dart';
import 'package:meeting_place_control_plane_api/src/api/delete_pending_notifications/request_validator.dart';
import 'package:meeting_place_control_plane_api/src/api/deregister_notification/request_model.dart';
import 'package:meeting_place_control_plane_api/src/api/deregister_notification/request_validator.dart';
import 'package:meeting_place_control_plane_api/src/api/group_send_message/request_model.dart';
import 'package:meeting_place_control_plane_api/src/api/group_send_message/request_validator.dart';
import 'package:meeting_place_control_plane_api/src/api/register_device/request_model.dart';
import 'package:meeting_place_control_plane_api/src/api/register_device/request_validator.dart';
import 'package:meeting_place_control_plane_api/src/api/register_offer/request_model.dart';
import 'package:meeting_place_control_plane_api/src/api/register_offer/request_validator.dart';
import 'package:meeting_place_control_plane_api/src/api/register_offer_group/request_model.dart';
import 'package:meeting_place_control_plane_api/src/api/register_offer_group/request_validator.dart';
import 'package:meeting_place_control_plane_api/src/api/update_offers_score/request_model.dart';
import 'package:meeting_place_control_plane_api/src/api/update_offers_score/request_validator.dart';
import 'package:meeting_place_control_plane_api/src/utils/platform_type.dart';
import 'package:test/test.dart';

void main() {
  group('RegisterOfferRequestValidator', () {
    test('validates valid request', () {
      final request = RegisterOfferRequest(
        offerName: 'test',
        offerDescription: 'description',
        didcommMessage: 'message',
        contactCard: 'contactCard',
        deviceToken: 'token',
        platformType: PlatformType.PUSH_NOTIFICATION,
        mediatorDid: 'did:example:123',
        mediatorEndpoint: 'https://mediator.example.com',
        mediatorWSSEndpoint: 'wss://mediator.example.com',
        contactAttributes: 1,
        score: 10,
      );

      final result = RegisterOfferRequestValidator().validate(request.toJson());
      expect(result.isValid, true);
    });

    test('fails when offerName is empty', () {
      final request = RegisterOfferRequest(
        offerName: '',
        offerDescription: 'description',
        didcommMessage: 'message',
        contactCard: 'contactCard',
        deviceToken: 'token',
        platformType: PlatformType.PUSH_NOTIFICATION,
        mediatorDid: 'did:example:123',
        mediatorEndpoint: 'https://mediator.example.com',
        mediatorWSSEndpoint: 'wss://mediator.example.com',
        contactAttributes: 1,
      );

      final result = RegisterOfferRequestValidator().validate(request.toJson());
      expect(result.isValid, false);
      expect(result.exceptions.any((e) => e.key == 'offerName'), true);
    });

    test('fails when offerName exceeds 500 characters', () {
      final request = RegisterOfferRequest(
        offerName: 'a' * 501,
        offerDescription: 'description',
        didcommMessage: 'message',
        contactCard: 'contactCard',
        deviceToken: 'token',
        platformType: PlatformType.PUSH_NOTIFICATION,
        mediatorDid: 'did:example:123',
        mediatorEndpoint: 'https://mediator.example.com',
        mediatorWSSEndpoint: 'wss://mediator.example.com',
        contactAttributes: 1,
      );

      final result = RegisterOfferRequestValidator().validate(request.toJson());
      expect(result.isValid, false);
      expect(result.exceptions.any((e) => e.key == 'offerName'), true);
    });

    test('fails when offerDescription exceeds 2000 characters', () {
      final request = RegisterOfferRequest(
        offerName: 'test',
        offerDescription: 'a' * 2001,
        didcommMessage: 'message',
        contactCard: 'contactCard',
        deviceToken: 'token',
        platformType: PlatformType.PUSH_NOTIFICATION,
        mediatorDid: 'did:example:123',
        mediatorEndpoint: 'https://mediator.example.com',
        mediatorWSSEndpoint: 'wss://mediator.example.com',
        contactAttributes: 1,
      );

      final result = RegisterOfferRequestValidator().validate(request.toJson());
      expect(result.isValid, false);
      expect(result.exceptions.any((e) => e.key == 'offerDescription'), true);
    });

    test('fails when deviceToken exceeds 2048 characters', () {
      final request = RegisterOfferRequest(
        offerName: 'test',
        offerDescription: 'description',
        didcommMessage: 'message',
        contactCard: 'contactCard',
        deviceToken: 'a' * 2049,
        platformType: PlatformType.PUSH_NOTIFICATION,
        mediatorDid: 'did:example:123',
        mediatorEndpoint: 'https://mediator.example.com',
        mediatorWSSEndpoint: 'wss://mediator.example.com',
        contactAttributes: 1,
      );

      final result = RegisterOfferRequestValidator().validate(request.toJson());
      expect(result.isValid, false);
      expect(result.exceptions.any((e) => e.key == 'deviceToken'), true);
    });

    test('fails when contactAttributes is negative', () {
      final request = RegisterOfferRequest(
        offerName: 'test',
        offerDescription: 'description',
        didcommMessage: 'message',
        contactCard: 'contactCard',
        deviceToken: 'token',
        platformType: PlatformType.PUSH_NOTIFICATION,
        mediatorDid: 'did:example:123',
        mediatorEndpoint: 'https://mediator.example.com',
        mediatorWSSEndpoint: 'wss://mediator.example.com',
        contactAttributes: -1,
      );

      final result = RegisterOfferRequestValidator().validate(request.toJson());
      expect(result.isValid, false);
      expect(result.exceptions.any((e) => e.key == 'contactAttributes'), true);
    });

    test('fails when maximumUsage is less than 1', () {
      final request = RegisterOfferRequest(
        offerName: 'test',
        offerDescription: 'description',
        didcommMessage: 'message',
        contactCard: 'contactCard',
        deviceToken: 'token',
        platformType: PlatformType.PUSH_NOTIFICATION,
        mediatorDid: 'did:example:123',
        mediatorEndpoint: 'https://mediator.example.com',
        mediatorWSSEndpoint: 'wss://mediator.example.com',
        contactAttributes: 1,
        maximumUsage: 0,
      );

      final result = RegisterOfferRequestValidator().validate(request.toJson());
      expect(result.isValid, false);
      expect(result.exceptions.any((e) => e.key == 'maximumUsage'), true);
    });

    test('validates valid ISO8601 UTC date for validUntil', () {
      final futureDate = DateTime.now()
          .toUtc()
          .add(Duration(days: 1))
          .toIso8601String();

      final request = RegisterOfferRequest(
        offerName: 'test',
        offerDescription: 'description',
        didcommMessage: 'message',
        contactCard: 'contactCard',
        deviceToken: 'token',
        platformType: PlatformType.PUSH_NOTIFICATION,
        mediatorDid: 'did:example:123',
        mediatorEndpoint: 'https://mediator.example.com',
        mediatorWSSEndpoint: 'wss://mediator.example.com',
        contactAttributes: 1,
        validUntil: futureDate,
      );

      final result = RegisterOfferRequestValidator().validate(request.toJson());
      expect(result.isValid, true);
    });

    test('fails when validUntil is in the past', () {
      final pastDate = DateTime.now()
          .toUtc()
          .subtract(Duration(days: 1))
          .toIso8601String();

      final request = RegisterOfferRequest(
        offerName: 'test',
        offerDescription: 'description',
        didcommMessage: 'message',
        contactCard: 'contactCard',
        deviceToken: 'token',
        platformType: PlatformType.PUSH_NOTIFICATION,
        mediatorDid: 'did:example:123',
        mediatorEndpoint: 'https://mediator.example.com',
        mediatorWSSEndpoint: 'wss://mediator.example.com',
        contactAttributes: 1,
        validUntil: pastDate,
      );

      final result = RegisterOfferRequestValidator().validate(request.toJson());
      expect(result.isValid, false);
      expect(result.exceptions.any((e) => e.key == 'validUntil'), true);
    });

    test('fails when validUntil is not ISO8601 format', () {
      final request = RegisterOfferRequest(
        offerName: 'test',
        offerDescription: 'description',
        didcommMessage: 'message',
        contactCard: 'contactCard',
        deviceToken: 'token',
        platformType: PlatformType.PUSH_NOTIFICATION,
        mediatorDid: 'did:example:123',
        mediatorEndpoint: 'https://mediator.example.com',
        mediatorWSSEndpoint: 'wss://mediator.example.com',
        contactAttributes: 1,
        validUntil: '2024-13-45',
      );

      final result = RegisterOfferRequestValidator().validate(request.toJson());
      expect(result.isValid, false);
      expect(result.exceptions.any((e) => e.key == 'validUntil'), true);
    });

    test('fails when validUntil is not UTC', () {
      final request = RegisterOfferRequest(
        offerName: 'test',
        offerDescription: 'description',
        didcommMessage: 'message',
        contactCard: 'contactCard',
        deviceToken: 'token',
        platformType: PlatformType.PUSH_NOTIFICATION,
        mediatorDid: 'did:example:123',
        mediatorEndpoint: 'https://mediator.example.com',
        mediatorWSSEndpoint: 'wss://mediator.example.com',
        contactAttributes: 1,
        validUntil: '2025-12-31T23:59:59+00:00',
      );

      final result = RegisterOfferRequestValidator().validate(request.toJson());
      expect(result.isValid, false);
      expect(result.exceptions.any((e) => e.key == 'validUntil'), true);
    });

    test('fails when score is negative', () {
      final request = RegisterOfferRequest(
        offerName: 'test',
        offerDescription: 'description',
        didcommMessage: 'message',
        contactCard: 'contactCard',
        deviceToken: 'token',
        platformType: PlatformType.PUSH_NOTIFICATION,
        mediatorDid: 'did:example:123',
        mediatorEndpoint: 'https://mediator.example.com',
        mediatorWSSEndpoint: 'wss://mediator.example.com',
        contactAttributes: 1,
        score: -1,
      );

      final result = RegisterOfferRequestValidator().validate(request.toJson());
      expect(result.isValid, false);
      expect(result.exceptions.any((e) => e.key == 'score'), true);
    });
  });

  group('RegisterOfferGroupRequestValidator', () {
    test('validates valid request', () {
      final request = RegisterOfferGroupRequest(
        offerName: 'test',
        offerDescription: 'description',
        didcommMessage: 'message',
        contactCard: 'contactCard',
        deviceToken: 'token',
        platformType: PlatformType.PUSH_NOTIFICATION,
        mediatorDid: 'did:example:123',
        mediatorEndpoint: 'https://mediator.example.com',
        mediatorWSSEndpoint: 'wss://mediator.example.com',
        adminReencryptionKey: 'key',
        adminDid: 'did:example:admin',
        adminPublicKey: 'publickey',
        memberContactCard: 'memberContactCard',
      );

      final result = RegisterOfferGroupRequestValidator().validate(
        request.toJson(),
      );
      expect(result.isValid, true);
    });

    test('fails when adminReencryptionKey is empty', () {
      final request = RegisterOfferGroupRequest(
        offerName: 'test',
        offerDescription: 'description',
        didcommMessage: 'message',
        contactCard: 'contactCard',
        deviceToken: 'token',
        platformType: PlatformType.PUSH_NOTIFICATION,
        mediatorDid: 'did:example:123',
        mediatorEndpoint: 'https://mediator.example.com',
        mediatorWSSEndpoint: 'wss://mediator.example.com',
        adminReencryptionKey: '',
        adminDid: 'did:example:admin',
        adminPublicKey: 'publickey',
        memberContactCard: 'memberContactCard',
      );

      final result = RegisterOfferGroupRequestValidator().validate(
        request.toJson(),
      );
      expect(result.isValid, false);
      expect(
        result.exceptions.any((e) => e.key == 'adminReencryptionKey'),
        true,
      );
    });

    test('validates valid ISO8601 UTC date for validUntil', () {
      final futureDate = DateTime.now()
          .toUtc()
          .add(Duration(days: 1))
          .toIso8601String();

      final request = RegisterOfferGroupRequest(
        offerName: 'test',
        offerDescription: 'description',
        didcommMessage: 'message',
        contactCard: 'contactCard',
        deviceToken: 'token',
        platformType: PlatformType.PUSH_NOTIFICATION,
        mediatorDid: 'did:example:123',
        mediatorEndpoint: 'https://mediator.example.com',
        mediatorWSSEndpoint: 'wss://mediator.example.com',
        adminReencryptionKey: 'key',
        adminDid: 'did:example:admin',
        adminPublicKey: 'publickey',
        memberContactCard: 'memberContactCard',
        validUntil: futureDate,
      );

      final result = RegisterOfferGroupRequestValidator().validate(
        request.toJson(),
      );
      expect(result.isValid, true);
    });

    test('fails when validUntil is in the past', () {
      final pastDate = DateTime.now()
          .toUtc()
          .subtract(Duration(days: 1))
          .toIso8601String();

      final request = RegisterOfferGroupRequest(
        offerName: 'test',
        offerDescription: 'description',
        didcommMessage: 'message',
        contactCard: 'contactCard',
        deviceToken: 'token',
        platformType: PlatformType.PUSH_NOTIFICATION,
        mediatorDid: 'did:example:123',
        mediatorEndpoint: 'https://mediator.example.com',
        mediatorWSSEndpoint: 'wss://mediator.example.com',
        adminReencryptionKey: 'key',
        adminDid: 'did:example:admin',
        adminPublicKey: 'publickey',
        memberContactCard: 'memberContactCard',
        validUntil: pastDate,
      );

      final result = RegisterOfferGroupRequestValidator().validate(
        request.toJson(),
      );
      expect(result.isValid, false);
      expect(result.exceptions.any((e) => e.key == 'validUntil'), true);
    });
  });

  group('AcceptOfferRequestValidator', () {
    test('validates valid request', () {
      final request = AcceptOfferRequest(
        did: 'did:example:123',
        mnemonic: 'word1 word2 word3',
        deviceToken: 'token',
        platformType: PlatformType.DIDCOMM,
        contactCard: 'contactCard',
      );

      final result = AcceptOfferRequestValidator().validate(request.toJson());
      expect(result.isValid, true);
    });

    test('fails when did is empty', () {
      final request = AcceptOfferRequest(
        did: '',
        mnemonic: 'word1 word2 word3',
        deviceToken: 'token',
        platformType: PlatformType.DIDCOMM,
        contactCard: 'contactCard',
      );

      final result = AcceptOfferRequestValidator().validate(request.toJson());
      expect(result.isValid, false);
      expect(result.exceptions.any((e) => e.key == 'did'), true);
    });

    test('fails when mnemonic is empty', () {
      final request = AcceptOfferRequest(
        did: 'did:example:123',
        mnemonic: '',
        deviceToken: 'token',
        platformType: PlatformType.DIDCOMM,
        contactCard: 'contactCard',
      );

      final result = AcceptOfferRequestValidator().validate(request.toJson());
      expect(result.isValid, false);
      expect(result.exceptions.any((e) => e.key == 'mnemonic'), true);
    });

    test('fails when contactCard is empty', () {
      final request = AcceptOfferRequest(
        did: 'did:example:123',
        mnemonic: 'word1 word2 word3',
        deviceToken: 'token',
        platformType: PlatformType.DIDCOMM,
        contactCard: '',
      );

      final result = AcceptOfferRequestValidator().validate(request.toJson());
      expect(result.isValid, false);
      expect(result.exceptions.any((e) => e.key == 'contactCard'), true);
    });

    test('fails when deviceToken exceeds 2048 characters', () {
      final request = AcceptOfferRequest(
        did: 'did:example:123',
        mnemonic: 'word1 word2 word3',
        deviceToken: 'a' * 2049,
        platformType: PlatformType.DIDCOMM,
        contactCard: 'contactCard',
      );

      final result = AcceptOfferRequestValidator().validate(request.toJson());
      expect(result.isValid, false);
      expect(result.exceptions.any((e) => e.key == 'deviceToken'), true);
    });
  });

  group('CheckOfferPhraseRequestValidator', () {
    test('validates valid request', () {
      final request = CheckOfferPhraseRequest(offerPhrase: 'word1 word2 word3');

      final result = CheckOfferPhraseRequestValidator().validate(
        request.toJson(),
      );
      expect(result.isValid, true);
    });

    test('fails when offerPhrase is empty', () {
      final request = CheckOfferPhraseRequest(offerPhrase: '');

      final result = CheckOfferPhraseRequestValidator().validate(
        request.toJson(),
      );
      expect(result.isValid, false);
      expect(result.exceptions.any((e) => e.key == 'offerPhrase'), true);
    });
  });

  group('AcceptOfferGroupRequestValidator', () {
    test('validates valid request', () {
      final request = AcceptOfferGroupRequest(
        did: 'did:example:123',
        mnemonic: 'word1 word2 word3',
        deviceToken: 'token',
        platformType: PlatformType.PUSH_NOTIFICATION,
        contactCard: 'contactCard',
      );

      final result = AcceptOfferGroupRequestValidator().validate(
        request.toJson(),
      );
      expect(result.isValid, true);
    });

    test('fails when required fields are empty', () {
      final request = AcceptOfferGroupRequest(
        did: '',
        mnemonic: 'word1 word2 word3',
        deviceToken: 'token',
        platformType: PlatformType.PUSH_NOTIFICATION,
        contactCard: 'contactCard',
      );

      final result = AcceptOfferGroupRequestValidator().validate(
        request.toJson(),
      );
      expect(result.isValid, false);
      expect(result.exceptions.any((e) => e.key == 'did'), true);
    });
  });

  group('RegisterDeviceRequestValidator', () {
    test('validates valid request', () {
      final request = RegisterDeviceRequest(
        deviceToken: 'token123',
        platformType: PlatformType.DIDCOMM,
      );

      final result = RegisterDeviceRequestValidator().validate(
        request.toJson(),
      );
      expect(result.isValid, true);
    });

    test('fails when deviceToken is empty', () {
      final request = RegisterDeviceRequest(
        deviceToken: '',
        platformType: PlatformType.DIDCOMM,
      );

      final result = RegisterDeviceRequestValidator().validate(
        request.toJson(),
      );
      expect(result.isValid, false);
      expect(result.exceptions.any((e) => e.key == 'deviceToken'), true);
    });

    test('fails when deviceToken exceeds 2048 characters', () {
      final request = RegisterDeviceRequest(
        deviceToken: 'a' * 2049,
        platformType: PlatformType.DIDCOMM,
      );

      final result = RegisterDeviceRequestValidator().validate(
        request.toJson(),
      );
      expect(result.isValid, false);
      expect(result.exceptions.any((e) => e.key == 'deviceToken'), true);
    });
  });

  group('DeletePendingNotificationsRequestValidator', () {
    test('validates valid request', () {
      final request = DeletePendingNotificationsRequest(
        deviceToken: 'token123',
        platformType: PlatformType.PUSH_NOTIFICATION,
        notificationIds: ['id1', 'id2'],
      );

      final result = DeletePendingNotificationsRequestValidator().validate(
        request.toJson(),
      );
      expect(result.isValid, true);
    });

    test('fails when deviceToken is empty', () {
      final request = DeletePendingNotificationsRequest(
        deviceToken: '',
        platformType: PlatformType.PUSH_NOTIFICATION,
        notificationIds: ['id1'],
      );

      final result = DeletePendingNotificationsRequestValidator().validate(
        request.toJson(),
      );
      expect(result.isValid, false);
      expect(result.exceptions.any((e) => e.key == 'deviceToken'), true);
    });

    test('fails when notificationIds is empty', () {
      final request = DeletePendingNotificationsRequest(
        deviceToken: 'token123',
        platformType: PlatformType.PUSH_NOTIFICATION,
        notificationIds: [],
      );

      final result = DeletePendingNotificationsRequestValidator().validate(
        request.toJson(),
      );
      expect(result.isValid, false);
      expect(result.exceptions.any((e) => e.key == 'notificationIds'), true);
    });

    test('fails when deviceToken exceeds 2048 characters', () {
      final request = DeletePendingNotificationsRequest(
        deviceToken: 'a' * 2049,
        platformType: PlatformType.PUSH_NOTIFICATION,
        notificationIds: ['id1'],
      );

      final result = DeletePendingNotificationsRequestValidator().validate(
        request.toJson(),
      );
      expect(result.isValid, false);
      expect(result.exceptions.any((e) => e.key == 'deviceToken'), true);
    });
  });

  group('DeregisterNotificationRequestValidator', () {
    test('validates valid request', () {
      final request = DeregisterNotificationRequest(
        notificationToken: 'token123',
      );

      final result = DeregisterNotificationRequestValidator().validate(
        request.toJson(),
      );
      expect(result.isValid, true);
    });

    test('fails when notificationToken is empty', () {
      final request = DeregisterNotificationRequest(notificationToken: '');

      final result = DeregisterNotificationRequestValidator().validate(
        request.toJson(),
      );
      expect(result.isValid, false);
      expect(result.exceptions.any((e) => e.key == 'notificationToken'), true);
    });
  });

  group('GroupSendMessageValidator', () {
    test('validates valid request', () {
      final request = GroupSendMessage(
        offerLink: 'link123',
        groupDid: 'did:example:group',
        payload: 'message payload',
        ephemeral: true,
        expiresTime: null,
      );

      final result = GroupSendMessageValidator().validate(request.toJson());
      expect(result.isValid, true);
    });

    test('fails when offerLink is empty', () {
      final request = GroupSendMessage(
        offerLink: '',
        groupDid: 'did:example:group',
        payload: 'message payload',
        ephemeral: true,
        expiresTime: null,
      );

      final result = GroupSendMessageValidator().validate(request.toJson());
      expect(result.isValid, false);
      expect(result.exceptions.any((e) => e.key == 'offerLink'), true);
    });

    test('fails when groupDid is empty', () {
      final request = GroupSendMessage(
        offerLink: 'link123',
        groupDid: '',
        payload: 'message payload',
        ephemeral: true,
        expiresTime: null,
      );

      final result = GroupSendMessageValidator().validate(request.toJson());
      expect(result.isValid, false);
      expect(result.exceptions.any((e) => e.key == 'groupDid'), true);
    });

    test('fails when payload is empty', () {
      final request = GroupSendMessage(
        offerLink: 'link123',
        groupDid: 'did:example:group',
        payload: '',
        ephemeral: true,
        expiresTime: null,
      );

      final result = GroupSendMessageValidator().validate(request.toJson());
      expect(result.isValid, false);
      expect(result.exceptions.any((e) => e.key == 'payload'), true);
    });

    test('validates request with expiresTime', () {
      final request = GroupSendMessage(
        offerLink: 'link123',
        groupDid: 'did:example:group',
        payload: 'message payload',
        ephemeral: false,
        expiresTime: '2025-12-31T23:59:59Z',
      );

      final result = GroupSendMessageValidator().validate(request.toJson());
      expect(result.isValid, true);
    });

    test('fails when expiresTime is empty string', () {
      final request = GroupSendMessage(
        offerLink: 'link123',
        groupDid: 'did:example:group',
        payload: 'message payload',
        ephemeral: false,
        expiresTime: '',
      );

      final result = GroupSendMessageValidator().validate(request.toJson());
      expect(result.isValid, false);
      expect(result.exceptions.any((e) => e.key == 'expiresTime'), true);
    });
  });

  group('UpdateOffersScoreRequestValidator', () {
    test('validates valid request', () {
      final request = UpdateOffersScoreRequest(
        score: 5,
        mnemonics: ['mnemonic1', 'mnemonic2'],
      );
      final result = UpdateOffersScoreRequestValidator().validate(
        request.toJson(),
      );
      expect(result.isValid, true);
    });

    test('fails when score is negative', () {
      final request = UpdateOffersScoreRequest(
        score: -1,
        mnemonics: ['mnemonic1'],
      );
      final result = UpdateOffersScoreRequestValidator().validate(
        request.toJson(),
      );
      expect(result.isValid, false);
      expect(result.exceptions.any((e) => e.key == 'score'), true);
    });

    test('fails when mnemonics is empty', () {
      final request = UpdateOffersScoreRequest(score: 1, mnemonics: []);
      final result = UpdateOffersScoreRequestValidator().validate(
        request.toJson(),
      );
      expect(result.isValid, false);
      expect(result.exceptions.any((e) => e.key == 'mnemonics'), true);
    });

    test('fails when mnemonics is null', () {
      final result = UpdateOffersScoreRequestValidator().validate({
        'score': 1,
        'mnemonics': null,
      });
      expect(result.isValid, false);
      expect(result.exceptions.any((e) => e.key == 'mnemonics'), true);
    });
  });
}
