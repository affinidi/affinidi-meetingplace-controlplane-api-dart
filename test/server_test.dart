import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:api_meetingplace_dart_oss/src/api/accept_offer/response_error_model.dart';
import 'package:api_meetingplace_dart_oss/src/api/check_offer_phrase/request_model.dart';
import 'package:api_meetingplace_dart_oss/src/api/create_oob/request_model.dart';
import 'package:api_meetingplace_dart_oss/src/api/delete_pending_notifications/request_model.dart';
import 'package:api_meetingplace_dart_oss/src/api/deregister_notification/request_model.dart';
import 'package:api_meetingplace_dart_oss/src/api/deregister_offer/request_model.dart';
import 'package:api_meetingplace_dart_oss/src/api/finalise_acceptance/request_model.dart';
import 'package:api_meetingplace_dart_oss/src/api/get_pending_notifications/request_model.dart';
import 'package:api_meetingplace_dart_oss/src/api/group_add_member/request_model.dart';
import 'package:api_meetingplace_dart_oss/src/api/group_add_member/response_error_model.dart';
import 'package:api_meetingplace_dart_oss/src/api/group_delete/request_model.dart';
import 'package:api_meetingplace_dart_oss/src/api/group_delete/response_error_model.dart';
import 'package:api_meetingplace_dart_oss/src/api/group_member_deregister/request_model.dart';
import 'package:api_meetingplace_dart_oss/src/api/group_member_deregister/response_error_model.dart';
import 'package:api_meetingplace_dart_oss/src/api/group_send_message/request_model.dart';
import 'package:api_meetingplace_dart_oss/src/api/notify_acceptance/request_model.dart';
import 'package:api_meetingplace_dart_oss/src/api/notify_channel/request_model.dart';
import 'package:api_meetingplace_dart_oss/src/api/notify_outreach/request_model.dart';
import 'package:api_meetingplace_dart_oss/src/api/query_offer/request_model.dart';
import 'package:api_meetingplace_dart_oss/src/api/register_device/request_model.dart';
import 'package:api_meetingplace_dart_oss/src/api/register_notification/request_model.dart';
import 'package:api_meetingplace_dart_oss/src/core/config/env_config.dart';
import 'package:api_meetingplace_dart_oss/src/core/did_resolver/did_resolver.dart';
import 'package:api_meetingplace_dart_oss/src/core/entity/offer.dart';
import 'package:api_meetingplace_dart_oss/src/utils/platform_type.dart';
import 'package:didcomm/didcomm.dart';
import 'package:dio/dio.dart';
import 'package:meeting_place_core/meeting_place_core.dart'
    show MeetingPlaceProtocol;
import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import 'package:proxy_recrypt/proxy_recrypt.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import 'mocks/accept_offer_group_request.dart';
import 'mocks/accept_offer_request.dart';
import 'mocks/devices.dart';
import 'mocks/register_offer_group_request.dart';
import 'mocks/register_offer_request.dart';
import 'utils/authoritzation.dart';
import 'utils/did_generator.dart';
import 'utils/recrypt.dart';

Uint8List generateRandomSeed(int length) {
  final random = Random.secure(); // Cryptographically secure
  final bytes = Uint8List(length);
  for (var i = 0; i < length; i++) {
    bytes[i] = random.nextInt(256); // value from 0 to 255
  }
  return bytes;
}

void main() {
  final apiEndpoint = getEnv('API_ENDPOINT');
  String getEncryptedMessageExample() {
    final recrypt = Recrypt();
    final recryptKeyPair = recrypt.generateKeyPair();
    final result = recrypt.encapsulate(recryptKeyPair.publicKey);

    return base64.encode(utf8.encode(jsonEncode({
      'ciphertext': 'cipher-sample',
      'capsule': (result['capsule'] as Capsule).toBase64(),
      'iv': 'iv-sample',
      'authenticationTag': 'auth-tag-sample',
    })));
  }

  late String aliceAccessToken;
  late String bobAccessToken;

  late Wallet aliceWallet;
  late Wallet bobWallet;

  final dio = Dio();

  setUp(() async {
    aliceWallet = PersistentWallet(InMemoryKeyStore());
    final aliceKeyPair = await aliceWallet.generateKey(keyId: "m/44'/60'/0'/0");

    final aliceDidManager =
        DidKeyManager(wallet: aliceWallet, store: InMemoryDidStore());
    await aliceDidManager.addVerificationMethod(aliceKeyPair.id);

    bobWallet = PersistentWallet(InMemoryKeyStore());
    final bobKeyPair = await bobWallet.generateKey(keyId: "m/44'/60'/0'/0");

    final bobDidManager =
        DidKeyManager(wallet: bobWallet, store: InMemoryDidStore());
    await bobDidManager.addVerificationMethod(bobKeyPair.id);

    aliceAccessToken = await handleAuthorization(aliceDidManager, aliceKeyPair);
    bobAccessToken = await handleAuthorization(bobDidManager, bobKeyPair);

    await dio.post(
      '$apiEndpoint/v1/register-device',
      data: RegisterDeviceRequest(
        deviceToken: AliceDevice.deviceToken,
        platformType: AliceDevice.platformType,
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    await dio.post(
      '$apiEndpoint/v1/register-device',
      data: RegisterDeviceRequest(
        deviceToken: BobDevice.deviceToken,
        platformType: BobDevice.platformType,
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': bobAccessToken,
      }),
    );
  });

  test('register-offer-group: sucess', () async {
    final registerOfferRequest = await getRegisterOfferGroupRequestMock(
      deviceToken: AliceDevice.deviceToken,
      platformType: AliceDevice.platformType,
      maximumUsage: 100,
      validUntil: DateTime.now()
          .toUtc()
          .add(const Duration(seconds: 300))
          .toIso8601String(),
    );

    final response = await dio.post(
      '$apiEndpoint/v1/register-offer-group',
      data: registerOfferRequest.toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    final findOfferResponse = await dio.post(
      '$apiEndpoint/v1/query-offer',
      data: {
        'did': await DidGenerator.generateDidKey(),
        'mnemonic': response.data['mnemonic'],
      },
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    expect(response.data['groupId'], isNotNull);
    expect(response.data['maximumUsage'], equals(100));
    expect(
      findOfferResponse.data['offerLink'],
      equals(response.data['offerLink']),
    );

    expect(
      findOfferResponse.data['name'],
      equals(registerOfferRequest.offerName),
    );

    expect(
      findOfferResponse.data['description'],
      equals(registerOfferRequest.offerDescription),
    );

    expect(
      findOfferResponse.data['vcard'],
      equals(registerOfferRequest.vcard),
    );

    expect(
      findOfferResponse.data['validUntil'],
      equals(response.data['validUntil']),
    );

    expect(
      findOfferResponse.data['didcommMessage'],
      equals(registerOfferRequest.didcommMessage),
    );

    expect(
      findOfferResponse.data['mediatorEndpoint'],
      equals(registerOfferRequest.mediatorEndpoint),
    );

    expect(
      findOfferResponse.data['mediatorWSSEndpoint'],
      equals(registerOfferRequest.mediatorWSSEndpoint),
    );
  });

  test('#accept-offer: success', () async {
    final registerOfferRequest = getRegisterOfferRequestMock(
      deviceToken: AliceDevice.deviceToken,
      platformType: AliceDevice.platformType,
    );

    final registerOfferResponse = await dio.post(
      '$apiEndpoint/v1/register-offer',
      data: registerOfferRequest.toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    final acceptOfferResponse = await dio.post(
      '$apiEndpoint/v1/accept-offer',
      data: getAcceptOfferRequest(
        did: BobDevice.offerAcceptanceDid,
        deviceToken: BobDevice.deviceToken,
        platformType: BobDevice.platformType,
        mnemonic: registerOfferResponse.data['mnemonic'],
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': bobAccessToken,
      }),
    );

    expect(
      acceptOfferResponse.data['didcommMessage'],
      registerOfferRequest.didcommMessage,
    );

    expect(
      acceptOfferResponse.data['offerLink'],
      registerOfferResponse.data['offerLink'],
    );

    expect(
      acceptOfferResponse.data['name'],
      registerOfferRequest.offerName,
    );

    expect(
      acceptOfferResponse.data['description'],
      registerOfferRequest.offerDescription,
    );

    expect(
      acceptOfferResponse.data['vcard'],
      registerOfferRequest.vcard,
    );

    expect(
      acceptOfferResponse.data['validUntil'],
      registerOfferResponse.data['validUntil'],
    );

    expect(
      acceptOfferResponse.data['mediatorEndpoint'],
      registerOfferRequest.mediatorEndpoint,
    );

    expect(
      acceptOfferResponse.data['mediatorWSSEndpoint'],
      registerOfferRequest.mediatorWSSEndpoint,
    );
  });

  test('#accept-offer: returns bad request if offer expired', () async {
    final registerOfferRequest = getRegisterOfferRequestMock(
      deviceToken: AliceDevice.deviceToken,
      platformType: AliceDevice.platformType,
      validUntil:
          DateTime.now().toUtc().add(Duration(seconds: 1)).toIso8601String(),
    );

    final registerOfferResponse = await dio.post(
      '$apiEndpoint/v1/register-offer',
      data: registerOfferRequest.toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    await Future.delayed(Duration(seconds: 2));

    expect(
        () => dio.post(
              '$apiEndpoint/v1/accept-offer',
              data: getAcceptOfferRequest(
                did: BobDevice.offerAcceptanceDid,
                deviceToken: BobDevice.deviceToken,
                platformType: BobDevice.platformType,
                mnemonic: registerOfferResponse.data['mnemonic'],
              ).toJson(),
              options: Options(headers: {
                Headers.contentTypeHeader: 'application/json',
                'authorization': aliceAccessToken,
              }),
            ), throwsA(
      predicate((e) {
        return e is DioException &&
            e.response?.statusCode == HttpStatus.badRequest &&
            e.response?.data['errorCode'] ==
                AcceptOfferErrorCodes.invalid.value &&
            e.response?.data['errorMessage'] == 'Offer is no longer valid';
      }),
    ));
  });

  test('#accept-offer: returns unauthorized if user is not authenticated',
      () async {
    try {
      await dio.post(
        '$apiEndpoint/v1/accept-offer',
        data: getAcceptOfferRequest(
          did: BobDevice.offerAcceptanceDid,
          deviceToken: BobDevice.deviceToken,
          platformType: BobDevice.platformType,
        ).toJson(),
        options: Options(headers: {
          Headers.contentTypeHeader: 'application/json',
        }),
      );
      fail('Expected dio exception');
    } on DioException catch (e) {
      expect(e.response?.statusCode, HttpStatus.forbidden);
      expect(e.response?.data, {
        'errorCode': 'AUTHORIZATION_TOKEN_NOT_PROVIDED',
        'errorMessage': 'No authorization token provided',
      });
    }
  });

  test('#accept-offer: return 404 if offer not found', () async {
    try {
      await Dio().post(
        '$apiEndpoint/v1/accept-offer',
        data: getAcceptOfferRequest(
          did: BobDevice.offerAcceptanceDid,
          deviceToken: BobDevice.deviceToken,
          platformType: BobDevice.platformType,
          mnemonic: 'does not exist',
        ).toJson(),
        options: Options(headers: {
          Headers.contentTypeHeader: 'application/json',
          'authorization': aliceAccessToken,
        }),
      );
    } on DioException catch (e) {
      expect(e.response?.statusCode, HttpStatus.notFound);
      expect(e.response?.data, {
        'errorCode': 'NOT_FOUND',
        'errorMessage': 'Offer not found. Offer acceptance not possible',
      });
    }
  });

  test('#accept-offer-group: success', () async {
    final registerOfferRequest = await getRegisterOfferGroupRequestMock(
      deviceToken: AliceDevice.deviceToken,
      platformType: AliceDevice.platformType,
    );

    final registerOfferResponse = await dio.post(
      '$apiEndpoint/v1/register-offer-group',
      data: registerOfferRequest.toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    final acceptOfferResponse = await dio.post(
      '$apiEndpoint/v1/accept-offer-group',
      data: getAcceptOfferGroupRequest(
        did: BobDevice.offerAcceptanceDid,
        deviceToken: BobDevice.deviceToken,
        platformType: BobDevice.platformType,
        mnemonic: registerOfferResponse.data['mnemonic'],
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    expect(
      acceptOfferResponse.data['didcommMessage'],
      registerOfferRequest.didcommMessage,
    );

    expect(
      acceptOfferResponse.data['offerLink'],
      registerOfferResponse.data['offerLink'],
    );

    expect(
      acceptOfferResponse.data['name'],
      registerOfferRequest.offerName,
    );

    expect(
      acceptOfferResponse.data['description'],
      registerOfferRequest.offerDescription,
    );

    expect(
      acceptOfferResponse.data['vcard'],
      registerOfferRequest.vcard,
    );

    expect(
      acceptOfferResponse.data['validUntil'],
      registerOfferResponse.data['validUntil'],
    );

    expect(
      acceptOfferResponse.data['mediatorEndpoint'],
      registerOfferRequest.mediatorEndpoint,
    );

    expect(
      acceptOfferResponse.data['mediatorWSSEndpoint'],
      registerOfferRequest.mediatorWSSEndpoint,
    );
  });

  test('#check-offer-phrase: mnemonic not in use', () async {
    final response = await dio.post(
      '$apiEndpoint/v1/check-offer-phrase',
      data: CheckOfferPhraseRequest(offerPhrase: 'does not exist').toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    expect(response.statusCode, HttpStatus.ok);
    expect(response.data['isInUse'], false);
  });

  test('#check-offer-phrase: mnemonic is in use', () async {
    final registerOfferResponse = await dio.post(
      '$apiEndpoint/v1/register-offer',
      data: getRegisterOfferRequestMock(
        deviceToken: AliceDevice.deviceToken,
        platformType: AliceDevice.platformType,
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    final response = await dio.post(
      '$apiEndpoint/v1/check-offer-phrase',
      data: CheckOfferPhraseRequest(
        offerPhrase: registerOfferResponse.data['mnemonic'],
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    expect(response.statusCode, HttpStatus.ok);
    expect(response.data['isInUse'], true);
  });

  test('#check-offer-phrase: returns unauthorized if user is not authenticated',
      () async {
    try {
      await dio.post(
        '$apiEndpoint/v1/check-offer-phrase',
        data: CheckOfferPhraseRequest(offerPhrase: 'world').toJson(),
        options: Options(headers: {
          Headers.contentTypeHeader: 'application/json',
        }),
      );
      fail('Expected dio exception');
    } on DioException catch (e) {
      expect(e.response?.statusCode, HttpStatus.forbidden);
      expect(e.response?.data, {
        'errorCode': 'AUTHORIZATION_TOKEN_NOT_PROVIDED',
        'errorMessage': 'No authorization token provided',
      });
    }
  });

  test('#create-oob: success', () async {
    final createOobResponse = await dio.post(
      '$apiEndpoint/v1/create-oob',
      data: CreateOobRequest(
        mediatorDid: 'did:web:mediator',
        mediatorEndpoint: 'https://mediator.yourdomain.com',
        mediatorWSSEndpoint: 'ws://mediator.yourdomain.com',
        didcommMessage: 'ZGlkY29tbW1lc3NhZ2UK',
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
      }),
    );

    expect(createOobResponse.statusCode, HttpStatus.ok);
    expect(createOobResponse.data['oobUrl'].startsWith(apiEndpoint), true);
  });

  test('#delete-pending-notifications: success', () async {
    final registerOfferResponse = await dio.post(
      '$apiEndpoint/v1/register-offer',
      data: getRegisterOfferRequestMock(
        deviceToken: AliceDevice.deviceToken,
        platformType: AliceDevice.platformType,
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    await dio.post(
      '$apiEndpoint/v1/accept-offer',
      data: getAcceptOfferRequest(
        did: BobDevice.offerAcceptanceDid,
        deviceToken: BobDevice.deviceToken,
        platformType: BobDevice.platformType,
        mnemonic: registerOfferResponse.data['mnemonic'],
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    await dio.post(
      '$apiEndpoint/v1/notify-acceptance',
      data: NotifyAcceptanceRequest(
        did: BobDevice.offerAcceptanceDid,
        offerLink: registerOfferResponse.data['offerLink'],
        mnemonic: registerOfferResponse.data['mnemonic'],
        senderInfo: 'Anonymous',
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    final getPendingNotificationsResponse = await dio.post(
      '$apiEndpoint/v1/notifications',
      data: GetPendingNotificationsRequest(
        deviceToken: AliceDevice.deviceToken,
        platformType: AliceDevice.platformType,
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    final notificationIds = getPendingNotificationsResponse
        .data['notifications']
        .map((n) => n['id'])
        .toList()
        .cast<String>();

    final response = await dio.post(
      '$apiEndpoint/v1/delete-notifications',
      data: DeletePendingNotificationsRequest(
        deviceToken: AliceDevice.deviceToken,
        platformType: AliceDevice.platformType,
        notificationIds: notificationIds,
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    expect(response.statusCode, HttpStatus.ok);
    expect(response.data['deletedIds'].length > 0, true);
    expect(response.data['notifications'] != null, true);
  });

  test('#deregister-notification: success', () async {
    final registerNotificationResponse = await dio.post(
      '$apiEndpoint/v1/register-notification',
      data: RegisterNotificationRequest(
        myDid: await DidGenerator.generateDidKey(),
        theirDid: await DidGenerator.generateDidKey(),
        deviceToken: AliceDevice.deviceToken,
        platformType: AliceDevice.platformType,
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    final response = await dio.post(
      '$apiEndpoint/v1/deregister-notification',
      data: DeregisterNotificationRequest(
        notificationToken:
            registerNotificationResponse.data['notificationToken'],
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    expect(response.statusCode, HttpStatus.ok);
    expect(response.data['status'], 'success');
  });

  test(
      '''#deregister-notification: fails with permission denied if requester is not the owner''',
      () async {
    final registerNotificationResponse = await dio.post(
      '$apiEndpoint/v1/register-notification',
      data: RegisterNotificationRequest(
        myDid: await DidGenerator.generateDidKey(),
        theirDid: await DidGenerator.generateDidKey(),
        deviceToken: AliceDevice.deviceToken,
        platformType: AliceDevice.platformType,
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    expect(
        () => dio.post(
              '$apiEndpoint/v1/deregister-notification',
              data: DeregisterNotificationRequest(
                notificationToken:
                    registerNotificationResponse.data['notificationToken'],
              ).toJson(),
              options: Options(headers: {
                Headers.contentTypeHeader: 'application/json',
                'authorization': bobAccessToken,
              }),
            ), throwsA(predicate((e) {
      return e is DioException &&
          e.response?.statusCode == HttpStatus.forbidden &&
          e.response?.data['errorCode'] == 'permission_denied' &&
          e.response?.data['errorMessage'] ==
              'Requester is not allowed to deregister given notification token';
    })));
  });

  test('#deregister-notification: fails with not found error', () async {
    expect(
        () => dio.post(
              '$apiEndpoint/v1/deregister-notification',
              data: DeregisterNotificationRequest(
                notificationToken: 'some-random-token',
              ).toJson(),
              options: Options(headers: {
                Headers.contentTypeHeader: 'application/json',
                'authorization': aliceAccessToken,
              }),
            ), throwsA(predicate((e) {
      return e is DioException &&
          e.response?.statusCode == HttpStatus.notFound &&
          e.response?.data['errorCode'] == 'not_found' &&
          e.response?.data['errorMessage'] == 'Notification channel not found';
    })));
  });

  test('#register-notification: success', () async {
    final response = await dio.post(
      '$apiEndpoint/v1/register-notification',
      data: RegisterNotificationRequest(
        myDid: await DidGenerator.generateDidKey(),
        theirDid: await DidGenerator.generateDidKey(),
        deviceToken: AliceDevice.deviceToken,
        platformType: AliceDevice.platformType,
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    expect(response.statusCode, HttpStatus.ok);
    expect(response.data['notificationToken'] != null, true);
  });

  test('#deregister-offer: success', () async {
    final registerOfferResponse = await dio.post(
      '$apiEndpoint/v1/register-offer',
      data: getRegisterOfferRequestMock(
        deviceToken: AliceDevice.deviceToken,
        platformType: AliceDevice.platformType,
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    final response = await dio.post(
      '$apiEndpoint/v1/deregister-offer',
      data: DeregisterOfferRequest(
        offerLink: registerOfferResponse.data['offerLink'],
        mnemonic: registerOfferResponse.data['mnemonic'],
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    expect(response.statusCode, HttpStatus.ok);
    expect(response.data, {
      'status': 'success',
      'message': 'Offer deleted successfully',
    });
  });

  test('#deregister-offer: fails if offer does not exist', () async {
    expect(
        () => dio.post(
              '$apiEndpoint/v1/deregister-offer',
              data: DeregisterOfferRequest(
                offerLink: 'offer-link',
                mnemonic: 'does not exist',
              ).toJson(),
              options: Options(headers: {
                Headers.contentTypeHeader: 'application/json',
                'authorization': aliceAccessToken,
              }),
            ), throwsA(
      predicate((e) {
        return e is DioException &&
            e.response?.statusCode == HttpStatus.conflict &&
            e.response?.data['errorCode'] == 'not_found' &&
            e.response?.data['errorMessage'] ==
                'Deregister offer exception: offer not found or it was already deleted';
      }),
    ));
  });

  test('#deregister-offer: fails if offer link does not match', () async {
    final registerOfferResponse = await dio.post(
      '$apiEndpoint/v1/register-offer',
      data: getRegisterOfferRequestMock(
        deviceToken: AliceDevice.deviceToken,
        platformType: AliceDevice.platformType,
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    expect(
        () => dio.post(
              '$apiEndpoint/v1/deregister-offer',
              data: DeregisterOfferRequest(
                offerLink: 'does-not-match',
                mnemonic: registerOfferResponse.data['mnemonic'],
              ).toJson(),
              options: Options(headers: {
                Headers.contentTypeHeader: 'application/json',
                'authorization': aliceAccessToken,
              }),
            ), throwsA(
      predicate((e) {
        return e is DioException &&
            e.response?.statusCode == HttpStatus.badRequest &&
            e.response?.data['errorCode'] == 'offer_link_mismatch' &&
            e.response?.data['errorMessage'] ==
                'Deregister offer exception: offer link does not match';
      }),
    ));
  });

  test('#deregister-offer: fails if user is not authorized', () async {
    final registerOfferResponse = await dio.post(
      '$apiEndpoint/v1/register-offer',
      data: getRegisterOfferRequestMock(
        deviceToken: AliceDevice.deviceToken,
        platformType: AliceDevice.platformType,
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    expect(
        () => dio.post(
              '$apiEndpoint/v1/deregister-offer',
              data: DeregisterOfferRequest(
                offerLink: registerOfferResponse.data['offerLink'],
                mnemonic: registerOfferResponse.data['mnemonic'],
              ).toJson(),
              options: Options(headers: {
                Headers.contentTypeHeader: 'application/json',
                'authorization': bobAccessToken,
              }),
            ), throwsA(
      predicate((e) {
        return e is DioException &&
            e.response?.statusCode == HttpStatus.forbidden &&
            e.response?.data['errorCode'] == 'permission_denied' &&
            e.response?.data['errorMessage'] ==
                '''Deregister offer exception: only offer owners are allowed to deregister offers''';
      }),
    ));
  });

  test('#finalise-acceptance: success', () async {
    final registerOfferResponse = await dio.post(
      '$apiEndpoint/v1/register-offer',
      data: getRegisterOfferRequestMock(
        deviceToken: AliceDevice.deviceToken,
        platformType: AliceDevice.platformType,
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    await dio.post(
      '$apiEndpoint/v1/accept-offer',
      data: getAcceptOfferRequest(
        did: BobDevice.offerAcceptanceDid,
        deviceToken: BobDevice.deviceToken,
        platformType: BobDevice.platformType,
        mnemonic: registerOfferResponse.data['mnemonic'],
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': bobAccessToken,
      }),
    );

    final response = await dio.post(
      '$apiEndpoint/v1/finalise-acceptance',
      data: FinaliseAcceptanceRequest(
        did: BobDevice.offerAcceptanceDid,
        theirDid: await DidGenerator.generateDidKey(),
        mnemonic: registerOfferResponse.data['mnemonic'],
        offerLink: registerOfferResponse.data['offerLink'],
        deviceToken: BobDevice.deviceToken,
        platformType: BobDevice.platformType,
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    expect(response.statusCode, HttpStatus.ok);
    expect(response.data['notificationToken'] != null, true);
  });

  test('#finalise-acceptance: success', () async {
    try {
      await dio.post(
        '$apiEndpoint/v1/finalise-acceptance',
        data: FinaliseAcceptanceRequest(
          did: BobDevice.offerAcceptanceDid,
          theirDid: await DidGenerator.generateDidKey(),
          mnemonic: 'mnemonic',
          offerLink: 'offer-link',
          deviceToken: BobDevice.deviceToken,
          platformType: BobDevice.platformType,
        ).toJson(),
        options: Options(headers: {
          Headers.contentTypeHeader: 'application/json',
        }),
      );
    } on DioException catch (e) {
      expect(e.response?.statusCode, HttpStatus.forbidden);
      expect(e.response?.data, {
        'errorCode': 'AUTHORIZATION_TOKEN_NOT_PROVIDED',
        'errorMessage': 'No authorization token provided',
      });
    }
  });

  test('#get-oob: success', () async {
    final createOobResponse = await dio.post(
      '$apiEndpoint/v1/create-oob',
      data: CreateOobRequest(
        mediatorDid: 'did:web:mediator',
        mediatorEndpoint: 'https://mediator.yourdomain.com',
        mediatorWSSEndpoint: 'ws://mediator.yourdomain.com',
        didcommMessage: 'ZGlkY29tbW1lc3NhZ2UK',
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
      }),
    );

    Uri uri = Uri.parse(createOobResponse.data['oobUrl']);
    final oobId = uri.pathSegments.last;

    final response = await dio.get(
      '$apiEndpoint/v1/oob/$oobId',
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
      }),
    );

    expect(response.statusCode, HttpStatus.ok);
    expect(
        response.data,
        equals({
          'oobId': oobId,
          'didcommMessage': 'ZGlkY29tbW1lc3NhZ2UK',
          'mediatorDid': 'did:web:mediator',
          'mediatorEndpoint': 'https://mediator.yourdomain.com',
          'mediatorWSSEndpoint': 'ws://mediator.yourdomain.com',
        }));
  });

  test('get-pending-notifications: sucess', () async {
    final registerOfferResponse = await dio.post(
      '$apiEndpoint/v1/register-offer',
      data: getRegisterOfferRequestMock(
        deviceToken: AliceDevice.deviceToken,
        platformType: AliceDevice.platformType,
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    await dio.post(
      '$apiEndpoint/v1/accept-offer',
      data: getAcceptOfferRequest(
        did: BobDevice.offerAcceptanceDid,
        deviceToken: BobDevice.deviceToken,
        platformType: BobDevice.platformType,
        mnemonic: registerOfferResponse.data['mnemonic'],
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': bobAccessToken,
      }),
    );

    await dio.post(
      '$apiEndpoint/v1/notify-acceptance',
      data: NotifyAcceptanceRequest(
        did: BobDevice.offerAcceptanceDid,
        offerLink: registerOfferResponse.data['offerLink'],
        mnemonic: registerOfferResponse.data['mnemonic'],
        senderInfo: 'Anonymous',
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': bobAccessToken,
      }),
    );

    final response = await dio.post(
      '$apiEndpoint/v1/notifications',
      data: GetPendingNotificationsRequest(
        deviceToken: AliceDevice.deviceToken,
        platformType: AliceDevice.platformType,
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    expect(response.statusCode, HttpStatus.ok);
    expect(response.data['notifications'].length > 0, true);
  });

  test('#notify-acceptance: success', () async {
    final registerOfferResponse = await dio.post(
      '$apiEndpoint/v1/register-offer',
      data: getRegisterOfferRequestMock(
        deviceToken: AliceDevice.deviceToken,
        platformType: AliceDevice.platformType,
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    await dio.post(
      '$apiEndpoint/v1/accept-offer',
      data: getAcceptOfferRequest(
        did: BobDevice.offerAcceptanceDid,
        deviceToken: BobDevice.deviceToken,
        platformType: BobDevice.platformType,
        mnemonic: registerOfferResponse.data['mnemonic'],
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': bobAccessToken,
      }),
    );

    final response = await dio.post(
      '$apiEndpoint/v1/notify-acceptance',
      data: NotifyAcceptanceRequest(
        did: BobDevice.offerAcceptanceDid,
        offerLink: registerOfferResponse.data['offerLink'],
        mnemonic: registerOfferResponse.data['mnemonic'],
        senderInfo: 'Anonymous',
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': bobAccessToken,
      }),
    );

    expect(response.statusCode, HttpStatus.ok);
    expect(response.data, null);
  });

  test('notify-acceptance: fails if offer does not exist', () async {
    try {
      await dio.post(
        '$apiEndpoint/v1/notify-acceptance',
        data: NotifyAcceptanceRequest(
          did: BobDevice.offerAcceptanceDid,
          offerLink: 'offer-link',
          mnemonic: 'mnemonic',
          senderInfo: 'Anonymous',
        ).toJson(),
        options: Options(headers: {
          Headers.contentTypeHeader: 'application/json',
          'authorization': bobAccessToken,
        }),
      );
    } on DioException catch (e) {
      expect(e.response?.statusCode, HttpStatus.badRequest);
      expect(e.response?.data, {
        'errorCode': 'OFFER_NOT_FOUND',
        'errorMessage': 'Offer not found, notify acceptance not possible',
      });
    }
  });

  test('notify-acceptance: fails if acceptance does not exist', () async {
    final registerOfferResponse = await dio.post(
      '$apiEndpoint/v1/register-offer',
      data: getRegisterOfferRequestMock(
        deviceToken: AliceDevice.deviceToken,
        platformType: AliceDevice.platformType,
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    try {
      await dio.post(
        '$apiEndpoint/v1/notify-acceptance',
        data: NotifyAcceptanceRequest(
          did: BobDevice.offerAcceptanceDid,
          offerLink: registerOfferResponse.data['offerLink'],
          mnemonic: registerOfferResponse.data['mnemonic'],
          senderInfo: 'Anonymous',
        ).toJson(),
        options: Options(headers: {
          Headers.contentTypeHeader: 'application/json',
          'authorization': bobAccessToken,
        }),
      );
    } on DioException catch (e) {
      expect(e.response?.statusCode, HttpStatus.badRequest);
      expect(e.response?.data, {
        'errorCode': 'ACCEPTANCE_NOT_FOUND',
        'errorMessage': 'Acceptance not found, notify acceptance not possible',
      });
    }
  });

  test('notify-acceptance: fails if user is not authorized', () async {
    try {
      await dio.post(
        '$apiEndpoint/v1/notify-acceptance',
        data: NotifyAcceptanceRequest(
          did: BobDevice.offerAcceptanceDid,
          offerLink: 'offer-link',
          mnemonic: 'mnemonic',
          senderInfo: 'Anonymous',
        ).toJson(),
        options: Options(headers: {
          Headers.contentTypeHeader: 'application/json',
        }),
      );
    } on DioException catch (e) {
      expect(e.response?.statusCode, HttpStatus.forbidden);
      expect(e.response?.data, {
        'errorCode': 'AUTHORIZATION_TOKEN_NOT_PROVIDED',
        'errorMessage': 'No authorization token provided',
      });
    }
  });

  test('#notify-channel: success', () async {
    final registerNotificationResponse = await dio.post(
      '$apiEndpoint/v1/register-notification',
      data: RegisterNotificationRequest(
        myDid: await DidGenerator.generateDidKey(),
        theirDid: await DidGenerator.generateDidKey(),
        deviceToken: AliceDevice.deviceToken,
        platformType: AliceDevice.platformType,
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    final response = await dio.post(
      '$apiEndpoint/v1/notify-channel',
      data: NotifyChannelRequest(
        notificationChannelId:
            registerNotificationResponse.data['notificationToken'],
        did: await DidGenerator.generateDidKey(),
        type: 'chat-activity',
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': bobAccessToken,
      }),
    );

    expect(response.statusCode, HttpStatus.ok);
    expect(response.data['notificationId'] != null, true);
  });

  test('notify-acceptance: fails if user is not authorized', () async {
    try {
      await dio.post(
        '$apiEndpoint/v1/notify-channel',
        data: NotifyChannelRequest(
          notificationChannelId: 'not-found',
          did: BobDevice.offerAcceptanceDid,
          type: 'chat-activity',
        ).toJson(),
        options: Options(headers: {
          Headers.contentTypeHeader: 'application/json',
        }),
      );
    } on DioException catch (e) {
      expect(e.response?.statusCode, HttpStatus.forbidden);
      expect(e.response?.data, {
        'errorCode': 'AUTHORIZATION_TOKEN_NOT_PROVIDED',
        'errorMessage': 'No authorization token provided',
      });
    }
  });

  test('#group-add-member: success', () async {
    final registerOfferRequest = await getRegisterOfferGroupRequestMock(
      deviceToken: AliceDevice.deviceToken,
      platformType: AliceDevice.platformType,
    );

    final registerOfferResponse = await dio.post(
      '$apiEndpoint/v1/register-offer-group',
      data: registerOfferRequest.toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    await dio.post(
      '$apiEndpoint/v1/accept-offer-group',
      data: getAcceptOfferGroupRequest(
        did: BobDevice.offerAcceptanceDid,
        deviceToken: BobDevice.deviceToken,
        platformType: BobDevice.platformType,
        mnemonic: registerOfferResponse.data['mnemonic'],
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': bobAccessToken,
      }),
    );

    final mediatorDid = registerOfferRequest.mediatorDid;
    final keyPair = await bobWallet.generateKey(keyId: "m/44'/60'/0'/1");

    final didManager = DidKeyManager(
      store: InMemoryDidStore(),
      wallet: bobWallet,
    );

    await didManager.addVerificationMethod(keyPair.id);
    final bobDidDoc = await didManager.getDidDocument();

    final sdk = MeetingPlaceMediatorSDK(
      mediatorDid: mediatorDid,
      didResolver: CachedDidResolver(),
    );

    await sdk.updateAcl(
      ownerDidManager: didManager,
      acl: AccessListAdd(ownerDid: bobDidDoc.id, granteeDids: [
        registerOfferResponse.data['groupDid'],
      ]),
      mediatorDid: mediatorDid,
    );

    final channel = await sdk.subscribeToMessages(
      didManager,
      mediatorDid: mediatorDid,
    );

    final receivedMessageCompleter = Completer<PlainTextMessage>();
    channel.listen((message) {
      if (message.type.toString() == MeetingPlaceProtocol.groupMessage.value) {
        receivedMessageCompleter.complete(message);
      }
    });

    final reencryptKeyPair = generateMemberRecryptKeyPair();
    final reencryptionKey = generateReEncryptionKey(reencryptKeyPair);

    final response = await dio.post(
      '$apiEndpoint/v1/group-add-member',
      data: GroupAddMemberRequest(
        offerLink: registerOfferResponse.data['offerLink'],
        mnemonic: registerOfferResponse.data['mnemonic'],
        groupId: registerOfferResponse.data['groupId'],
        memberDid: bobDidDoc.id,
        acceptOfferAsDid: BobDevice.offerAcceptanceDid,
        reencryptionKey: reencryptionKey.toBase64(),
        publicKey: reencryptKeyPair.publicKeyToBase64(),
        vcard: '',
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    expect(response.data['status'], equals('success'));
    expect(response.data['message'], equals('Group member added successfully'));
  });

  test('query-offer: success', () async {
    final registerOfferRequestMock = getRegisterOfferRequestMock(
      deviceToken: AliceDevice.deviceToken,
      platformType: AliceDevice.platformType,
    );

    final registerOfferResponse = await dio.post(
      '$apiEndpoint/v1/register-offer',
      data: registerOfferRequestMock.toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    final response = await dio.post(
      '$apiEndpoint/v1/query-offer',
      data: QueryOfferRequest(
        mnemonic: registerOfferResponse.data['mnemonic'],
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': bobAccessToken,
      }),
    );

    expect(response.statusCode, HttpStatus.ok);
    expect(response.data, {
      'offerLink': registerOfferResponse.data['offerLink'],
      'name': registerOfferRequestMock.offerName,
      'description': registerOfferRequestMock.offerDescription,
      'vcard': registerOfferRequestMock.vcard,
      'validUntil': registerOfferResponse.data['validUntil'],
      'maximumUsage': registerOfferResponse.data['maximumUsage'],
      'mediatorDid': registerOfferRequestMock.mediatorDid,
      'mediatorEndpoint': registerOfferRequestMock.mediatorEndpoint,
      'mediatorWSSEndpoint': registerOfferRequestMock.mediatorWSSEndpoint,
      'didcommMessage': registerOfferRequestMock.didcommMessage,
      'status': OfferStatus.created.value,
      'contactAttributes': registerOfferRequestMock.contactAttributes,
      'groupId': null,
      'groupDid': null,
    });
  });

  test('query-offer: group did and group id set if group offer', () async {
    final registerOfferRequestMock = await getRegisterOfferGroupRequestMock(
      deviceToken: AliceDevice.deviceToken,
      platformType: AliceDevice.platformType,
    );

    final registerOfferResponse = await dio.post(
      '$apiEndpoint/v1/register-offer-group',
      data: registerOfferRequestMock.toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    final response = await dio.post(
      '$apiEndpoint/v1/query-offer',
      data: QueryOfferRequest(
        mnemonic: registerOfferResponse.data['mnemonic'],
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': bobAccessToken,
      }),
    );

    expect(response.statusCode, HttpStatus.ok);
    expect(response.data['groupId'], isNotEmpty);
    expect(response.data['groupDid'], isNotEmpty);
  });

  test('query-offer: fails if offer does not exist', () async {
    try {
      await dio.post(
        '$apiEndpoint/v1/query-offer',
        data: QueryOfferRequest(
          mnemonic: 'does not exist',
        ).toJson(),
        options: Options(headers: {
          Headers.contentTypeHeader: 'application/json',
          'authorization': aliceAccessToken,
        }),
      );
    } on DioException catch (e) {
      expect(e.response?.statusCode, HttpStatus.notFound);
      expect(e.response?.data, {
        'errorCode': 'NOT_FOUND',
        'errorMessage': 'Offer not found',
      });
    }
  });

  test('query-offer: fails if query limit exceeded', () async {
    final registerOfferRequestMock = getRegisterOfferRequestMock(
      deviceToken: AliceDevice.deviceToken,
      platformType: AliceDevice.platformType,
      maximumUsage: 1,
    );

    final registerOfferResponse = await dio.post(
      '$apiEndpoint/v1/register-offer',
      data: registerOfferRequestMock.toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    await dio.post(
      '$apiEndpoint/v1/query-offer',
      data: QueryOfferRequest(
        mnemonic: registerOfferResponse.data['mnemonic'],
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': bobAccessToken,
      }),
    );

    try {
      await dio.post(
        '$apiEndpoint/v1/query-offer',
        data: QueryOfferRequest(
          mnemonic: registerOfferResponse.data['mnemonic'],
        ).toJson(),
        options: Options(headers: {
          Headers.contentTypeHeader: 'application/json',
          'authorization': bobAccessToken,
        }),
      );
    } on DioException catch (e) {
      expect(e.response?.statusCode, HttpStatus.badRequest);
      expect(e.response?.data, {
        'errorCode': 'QUERY_LIMIT_EXCEEDED',
        'errorMessage': 'Offer query limit exceeded',
      });
    }
  });

  test('query-offer: fails if user not authorized', () async {
    try {
      await dio.post(
        '$apiEndpoint/v1/query-offer',
        data: QueryOfferRequest(
          mnemonic: 'does not exist',
        ).toJson(),
        options: Options(headers: {
          Headers.contentTypeHeader: 'application/json',
        }),
      );
    } on DioException catch (e) {
      expect(e.response?.statusCode, HttpStatus.forbidden);
      expect(e.response?.data, {
        'errorCode': 'AUTHORIZATION_TOKEN_NOT_PROVIDED',
        'errorMessage': 'No authorization token provided',
      });
    }
  });

  test('#register-device: success for push notification', () async {
    final response = await dio.post(
      '$apiEndpoint/v1/register-device',
      data: RegisterDeviceRequest(
        deviceToken: AliceDevice.deviceToken,
        platformType: AliceDevice.platformType,
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );
    expect(response.statusCode, HttpStatus.ok);
    expect(response.data, {
      'status': 'SUCCEEDED',
      'message': 'Device registration succeeded',
      'deviceToken': AliceDevice.deviceToken,
      'platformType': AliceDevice.platformType.name,
    });
  });

  test('#register-device: success for DIDComm notification', () async {
    final response = await dio.post(
      '$apiEndpoint/v1/register-device',
      data: RegisterDeviceRequest(
        deviceToken: 'did:web:mediator.com::did:key:123456',
        platformType: PlatformType.DIDCOMM,
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );
    expect(response.statusCode, HttpStatus.ok);
    expect(response.data, {
      'status': 'SUCCEEDED',
      'message': 'Device registration succeeded',
      'deviceToken': 'did:web:mediator.com::did:key:123456',
      'platformType': PlatformType.DIDCOMM.name,
    });
  });

  test('#register-device: fails if user is not authorized', () async {
    try {
      await dio.post(
        '$apiEndpoint/v1/register-device',
        data: RegisterDeviceRequest(
          deviceToken: AliceDevice.deviceToken,
          platformType: AliceDevice.platformType,
        ).toJson(),
        options: Options(headers: {
          Headers.contentTypeHeader: 'application/json',
        }),
      );
    } on DioException catch (e) {
      expect(e.response?.statusCode, HttpStatus.forbidden);
      expect(e.response?.data, {
        'errorCode': 'AUTHORIZATION_TOKEN_NOT_PROVIDED',
        'errorMessage': 'No authorization token provided',
      });
    }
  });

  test('#register-offer: success', () async {
    final offerPhrase =
        'random ${Random().nextInt(26)}${Random().nextInt(26)}${Random().nextInt(26)} phrase';

    final validUntil =
        DateTime.now().toUtc().add(Duration(seconds: 300)).toIso8601String();
    final response = await dio.post(
      '$apiEndpoint/v1/register-offer',
      data: getRegisterOfferRequestMock(
        deviceToken: AliceDevice.deviceToken,
        platformType: AliceDevice.platformType,
        maximumUsage: 5,
        customPhrase: offerPhrase,
        validUntil: validUntil,
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    expect(response.statusCode, HttpStatus.ok);
    expect(response.data['offerLink'] != null, true);
    expect(response.data['mnemonic'], offerPhrase);
    expect(response.data['validUntil'], validUntil);
    expect(response.data['maximumUsage'], 5);
  });

  test('#register-offer: unlimited valid until and maximum usage', () async {
    final offerPhrase =
        'random ${Random().nextInt(26)}${Random().nextInt(26)}${Random().nextInt(26)} phrase';

    final request = getRegisterOfferRequestMock(
      deviceToken: AliceDevice.deviceToken,
      platformType: AliceDevice.platformType,
      customPhrase: offerPhrase,
      maximumUsage: null,
      validUntil: null,
    );

    final response = await dio.post(
      '$apiEndpoint/v1/register-offer',
      data: request.toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    expect(response.statusCode, HttpStatus.ok);
    expect(response.data['validUntil'], isNull);
    expect(response.data['maximumUsage'], isNull);

    final findOfferResponse = await dio.post(
      '$apiEndpoint/v1/query-offer',
      data: {
        'did': await DidGenerator.generateDidKey(),
        'mnemonic': response.data['mnemonic'],
      },
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    expect(findOfferResponse.data['validUntil'], isNull);
    expect(findOfferResponse.data['maximumUsage'], isNull);
  });

  test('#register-offer: return 409 if offer exists already', () async {
    final registerOfferResponse = await dio.post(
      '$apiEndpoint/v1/register-offer',
      data: getRegisterOfferRequestMock(
        deviceToken: AliceDevice.deviceToken,
        platformType: AliceDevice.platformType,
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    try {
      await dio.post(
        '$apiEndpoint/v1/register-offer',
        data: getRegisterOfferRequestMock(
          deviceToken: AliceDevice.deviceToken,
          platformType: AliceDevice.platformType,
          customPhrase: registerOfferResponse.data['mnemonic'],
        ).toJson(),
        options: Options(headers: {
          Headers.contentTypeHeader: 'application/json',
          'authorization': aliceAccessToken,
        }),
      );
    } on DioException catch (e) {
      expect(e.response?.statusCode, HttpStatus.conflict);
      expect(e.response?.data, {
        'offerLink': '',
        'mnemonic': '',
        'validUntil': null,
        'maximumUsage': null,
      });
    }
  });

  test('register-offer: fails if user not authorized', () async {
    try {
      await dio.post(
        '$apiEndpoint/v1/register-offer',
        data: getRegisterOfferRequestMock(
          deviceToken: AliceDevice.deviceToken,
          platformType: AliceDevice.platformType,
        ).toJson(),
        options: Options(headers: {
          Headers.contentTypeHeader: 'application/json',
        }),
      );
    } on DioException catch (e) {
      expect(e.response?.statusCode, HttpStatus.forbidden);
      expect(e.response?.data, {
        'errorCode': 'AUTHORIZATION_TOKEN_NOT_PROVIDED',
        'errorMessage': 'No authorization token provided',
      });
      return;
    }
    fail('Expected exception not thrown');
  });

  test('group-send-message: success', () async {
    final registerOfferRequest = await getRegisterOfferGroupRequestMock(
      deviceToken: AliceDevice.deviceToken,
      platformType: AliceDevice.platformType,
    );

    final registerOfferResponse = await dio.post(
      '$apiEndpoint/v1/register-offer-group',
      data: registerOfferRequest.toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    await dio.post(
      '$apiEndpoint/v1/accept-offer-group',
      data: getAcceptOfferGroupRequest(
        did: BobDevice.offerAcceptanceDid,
        deviceToken: BobDevice.deviceToken,
        platformType: BobDevice.platformType,
        mnemonic: registerOfferResponse.data['mnemonic'],
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': bobAccessToken,
      }),
    );

    final mediatorDid = registerOfferRequest.mediatorDid;
    final keyPair = await bobWallet.generateKey(keyId: "m/44'/60'/0'/1");

    final didManager = DidKeyManager(
      store: InMemoryDidStore(),
      wallet: bobWallet,
    );

    await didManager.addVerificationMethod(keyPair.id);
    final bobDidDoc = await didManager.getDidDocument();

    final sdk = MeetingPlaceMediatorSDK(
      mediatorDid: mediatorDid,
      didResolver: CachedDidResolver(),
    );

    await sdk.updateAcl(
      ownerDidManager: didManager,
      acl: AccessListAdd(ownerDid: bobDidDoc.id, granteeDids: [
        registerOfferResponse.data['groupDid'],
      ]),
      mediatorDid: mediatorDid,
    );

    final channel = await sdk.subscribeToMessages(
      didManager,
      mediatorDid: mediatorDid,
    );

    final receivedMessageCompleter = Completer<PlainTextMessage>();
    channel.listen((message) {
      if (message.type.toString() == MeetingPlaceProtocol.groupMessage.value) {
        receivedMessageCompleter.complete(message);
      }
    });

    final recrypt = Recrypt();
    final reencryptKeyPair = generateMemberRecryptKeyPair();
    final reencryptionKey = generateReEncryptionKey(reencryptKeyPair);

    await dio.post(
      '$apiEndpoint/v1/group-add-member',
      data: GroupAddMemberRequest(
        offerLink: registerOfferResponse.data['offerLink'],
        mnemonic: registerOfferResponse.data['mnemonic'],
        groupId: registerOfferResponse.data['groupId'],
        memberDid: bobDidDoc.id,
        acceptOfferAsDid: BobDevice.offerAcceptanceDid,
        reencryptionKey: reencryptionKey.toBase64(),
        publicKey: reencryptKeyPair.publicKeyToBase64(),
        vcard: '',
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    final recryptKeyPair = recrypt.generateKeyPair();
    final result = recrypt.encapsulate(recryptKeyPair.publicKey);

    final expCiphertext = 'cipher-sample';
    final expCapsule = (result['capsule'] as Capsule).toBase64();
    final expIV = 'iv-sample';
    final expAuthenticationTag = 'auth-tag-sample';

    await dio.post(
      '$apiEndpoint/v1/group-send-message',
      data: GroupSendMessage(
        offerLink: registerOfferResponse.data['offerLink'],
        groupDid: registerOfferResponse.data['groupDid'],
        payload: base64Encode(utf8.encode(jsonEncode(
          {
            'ciphertext': expCiphertext,
            'capsule': expCapsule,
            'iv': expIV,
            'authenticationTag': expAuthenticationTag,
          },
        ))),
        ephemeral: false,
        expiresTime: DateTime.now()
            .toUtc()
            .add(const Duration(seconds: 60))
            .toIso8601String(),
        notify: false,
        incSeqNo: true,
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    final receivedMessage = await receivedMessageCompleter.future;
    expect(receivedMessage.type.toString(),
        equals(MeetingPlaceProtocol.groupMessage.value));
    expect(receivedMessage.body!['ciphertext'], equals(expCiphertext));
    expect(receivedMessage.body!['iv'], equals(expIV));
    expect(receivedMessage.body!['authenticationTag'],
        equals(expAuthenticationTag));
    expect(receivedMessage.body!['preCapsule'], isNotNull);
    expect(receivedMessage.body!['fromDid'], registerOfferRequest.adminDid);
    expect(receivedMessage.body!['seqNo'], equals(1));
  });

  test('group-add-member: fails due to missing permissions', () async {
    final registerOfferRequest = await getRegisterOfferGroupRequestMock(
      deviceToken: AliceDevice.deviceToken,
      platformType: AliceDevice.platformType,
    );

    final registerOfferResponse = await dio.post(
      '$apiEndpoint/v1/register-offer-group',
      data: registerOfferRequest.toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    await dio.post(
      '$apiEndpoint/v1/accept-offer-group',
      data: getAcceptOfferGroupRequest(
        did: BobDevice.offerAcceptanceDid,
        deviceToken: BobDevice.deviceToken,
        platformType: BobDevice.platformType,
        mnemonic: registerOfferResponse.data['mnemonic'],
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': bobAccessToken,
      }),
    );

    final keyPair = await bobWallet.generateKey(keyId: "m/44'/60'/0'/1");

    final didManager = DidKeyManager(
      store: InMemoryDidStore(),
      wallet: bobWallet,
    );

    await didManager.addVerificationMethod(keyPair.id);
    final bobDidDoc = await didManager.getDidDocument();

    final reencryptKeyPair = generateMemberRecryptKeyPair();
    final reencryptionKey = generateReEncryptionKey(reencryptKeyPair);

    expect(
        () => dio.post(
              '$apiEndpoint/v1/group-add-member',
              data: GroupAddMemberRequest(
                offerLink: registerOfferResponse.data['offerLink'],
                mnemonic: registerOfferResponse.data['mnemonic'],
                groupId: registerOfferResponse.data['groupId'],
                memberDid: bobDidDoc.id,
                acceptOfferAsDid: BobDevice.offerAcceptanceDid,
                reencryptionKey: reencryptionKey.toBase64(),
                publicKey: reencryptKeyPair.publicKeyToBase64(),
                vcard: '',
              ).toJson(),
              options: Options(headers: {
                Headers.contentTypeHeader: 'application/json',
                'authorization': bobAccessToken,
              }),
            ),
        throwsA(predicate((e) =>
            e is DioException &&
            e.response?.statusCode == HttpStatus.forbidden &&
            e.response?.data['errorCode'] ==
                GroupAddMemberErrorCodes.permissionDenied.value &&
            e.response?.data['errorMessage'] ==
                '''Group add member exception: The requester does not have permission to add a member to the group.''')));
  });

  test('group-deregister-member: success', () async {
    final registerOfferRequest = await getRegisterOfferGroupRequestMock(
      deviceToken: AliceDevice.deviceToken,
      platformType: AliceDevice.platformType,
    );

    final registerOfferResponse = await dio.post(
      '$apiEndpoint/v1/register-offer-group',
      data: registerOfferRequest.toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    await dio.post(
      '$apiEndpoint/v1/accept-offer-group',
      data: getAcceptOfferGroupRequest(
        did: BobDevice.offerAcceptanceDid,
        deviceToken: BobDevice.deviceToken,
        platformType: BobDevice.platformType,
        mnemonic: registerOfferResponse.data['mnemonic'],
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    final keyPair = await bobWallet.generateKey(keyId: "m/44'/60'/0'/1");

    final didManager = DidKeyManager(
      store: InMemoryDidStore(),
      wallet: bobWallet,
    );

    await didManager.addVerificationMethod(keyPair.id);
    final bobDidDoc = await didManager.getDidDocument();

    final reencryptKeyPair = generateMemberRecryptKeyPair();
    final reencryptionKey = generateReEncryptionKey(reencryptKeyPair);

    await dio.post(
      '$apiEndpoint/v1/group-add-member',
      data: GroupAddMemberRequest(
        offerLink: registerOfferResponse.data['offerLink'],
        mnemonic: registerOfferResponse.data['mnemonic'],
        groupId: registerOfferResponse.data['groupId'],
        memberDid: bobDidDoc.id,
        acceptOfferAsDid: BobDevice.offerAcceptanceDid,
        reencryptionKey: reencryptionKey.toBase64(),
        publicKey: reencryptKeyPair.publicKeyToBase64(),
        vcard: '',
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    final response = await dio.post(
      '$apiEndpoint/v1/group-member-deregister',
      data: GroupMemberDeregisterRequest(
        groupId: registerOfferResponse.data['groupId'],
        memberDid: bobDidDoc.id,
        messageToRelay: getEncryptedMessageExample(),
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    expect(response.data['status'], equals('success'));
    expect(response.data['message'],
        equals('Group member deregistered successfully'));
  });

  test('group-deregister-member: fails because group was deleted already',
      () async {
    final registerOfferRequest = await getRegisterOfferGroupRequestMock(
      deviceToken: AliceDevice.deviceToken,
      platformType: AliceDevice.platformType,
    );

    final registerOfferResponse = await dio.post(
      '$apiEndpoint/v1/register-offer-group',
      data: registerOfferRequest.toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    await dio.post(
      '$apiEndpoint/v1/accept-offer-group',
      data: getAcceptOfferGroupRequest(
        did: BobDevice.offerAcceptanceDid,
        deviceToken: BobDevice.deviceToken,
        platformType: BobDevice.platformType,
        mnemonic: registerOfferResponse.data['mnemonic'],
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    final keyPair = await bobWallet.generateKey(keyId: "m/44'/60'/0'/1");

    final didManager = DidKeyManager(
      store: InMemoryDidStore(),
      wallet: bobWallet,
    );

    await didManager.addVerificationMethod(keyPair.id);
    final bobDidDoc = await didManager.getDidDocument();

    final reencryptKeyPair = generateMemberRecryptKeyPair();
    final reencryptionKey = generateReEncryptionKey(reencryptKeyPair);

    await dio.post(
      '$apiEndpoint/v1/group-add-member',
      data: GroupAddMemberRequest(
        offerLink: registerOfferResponse.data['offerLink'],
        mnemonic: registerOfferResponse.data['mnemonic'],
        groupId: registerOfferResponse.data['groupId'],
        memberDid: bobDidDoc.id,
        acceptOfferAsDid: BobDevice.offerAcceptanceDid,
        reencryptionKey: reencryptionKey.toBase64(),
        publicKey: reencryptKeyPair.toBase64(),
        vcard: '',
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    await dio.post(
      '$apiEndpoint/v1/group-delete',
      data: GroupDeleteRequest(
        groupId: registerOfferResponse.data['groupId'],
        messageToRelay: getEncryptedMessageExample(),
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    expect(
        () => dio.post(
              '$apiEndpoint/v1/group-member-deregister',
              data: GroupMemberDeregisterRequest(
                groupId: registerOfferResponse.data['groupId'],
                memberDid: bobDidDoc.id,
                messageToRelay: getEncryptedMessageExample(),
              ).toJson(),
              options: Options(headers: {
                Headers.contentTypeHeader: 'application/json',
                'authorization': aliceAccessToken,
              }),
            ), throwsA(
      predicate((e) {
        return e is DioException &&
            e.response?.statusCode == HttpStatus.gone &&
            e.response?.data['errorCode'] ==
                GroupMemberDeregisterErrorCodes.deleted.value &&
            e.response?.data['errorMessage'] ==
                'Deregister member failed: group has been deleted.';
      }),
    ));
  });

  test('group-delete: success', () async {
    final registerOfferGroupRequest = await getRegisterOfferGroupRequestMock(
      deviceToken: AliceDevice.deviceToken,
      platformType: AliceDevice.platformType,
    );

    final response = await dio.post(
      '$apiEndpoint/v1/register-offer-group',
      data: registerOfferGroupRequest.toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    final actual = await dio.post(
      '$apiEndpoint/v1/group-delete',
      data: GroupDeleteRequest(
        groupId: response.data!['groupId'],
        messageToRelay: getEncryptedMessageExample(),
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    expect(actual.data['status'], 'success');
    expect(actual.data['message'], 'Group deleted successfully');

    expect(
        () => dio.post(
              '$apiEndpoint/v1/group-delete',
              data: GroupDeleteRequest(
                groupId: response.data!['groupId'],
                messageToRelay: getEncryptedMessageExample(),
              ).toJson(),
              options: Options(headers: {
                Headers.contentTypeHeader: 'application/json',
                'authorization': aliceAccessToken,
              }),
            ), throwsA(
      predicate((e) {
        return e is DioException &&
            e.response?.statusCode == HttpStatus.gone &&
            e.response?.data['errorCode'] ==
                GroupDeleteErrorCodes.groupDeleted.value &&
            e.response?.data['errorMessage'] ==
                'Group delete exception: Group has been deleted';
      }),
    ));
  });

  test('group-delete: failure not owning the group', () async {
    final registerOfferGroupRequest = await getRegisterOfferGroupRequestMock(
      deviceToken: AliceDevice.deviceToken,
      platformType: AliceDevice.platformType,
    );

    final response = await dio.post(
      '$apiEndpoint/v1/register-offer-group',
      data: registerOfferGroupRequest.toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    try {
      await dio.post(
        '$apiEndpoint/v1/group-delete',
        data: GroupDeleteRequest(
          groupId: response.data!['groupId'],
          messageToRelay: getEncryptedMessageExample(),
        ).toJson(),
        options: Options(headers: {
          Headers.contentTypeHeader: 'application/json',
          'authorization': bobAccessToken,
        }),
      );
    } on DioException catch (e) {
      expect(e.response?.statusCode, HttpStatus.forbidden);
      expect(e.response?.data, {
        'errorCode': 'group_permission_denied',
        'errorMessage':
            'Group delete exception: only group owners are allowed to delete group',
      });
      return;
    }

    fail('Expected exception not thrown');
  });

  test('#notify-outreach: success', () async {
    final registerOfferResponse = await dio.post(
      '$apiEndpoint/v1/register-offer',
      data: getRegisterOfferRequestMock(
        deviceToken: AliceDevice.deviceToken,
        platformType: AliceDevice.platformType,
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    final notifyOutreachResponse = await dio.post(
      '$apiEndpoint/v1/notify-outreach',
      data: NotifyOutreachRequest(
        mnemonic: registerOfferResponse.data['mnemonic'],
        senderInfo: 'Bob',
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': bobAccessToken,
      }),
    );

    final notificationResponse = await dio.post(
      '$apiEndpoint/v1/notifications',
      data: GetPendingNotificationsRequest(
        deviceToken: AliceDevice.deviceToken,
        platformType: AliceDevice.platformType,
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    // Check endpoint response
    expect(notifyOutreachResponse.statusCode, equals(HttpStatus.ok));
    expect(notifyOutreachResponse.data['status'], equals('success'));
    expect(
      notifyOutreachResponse.data['message'],
      equals('Notify outreach successful'),
    );

    // Check if notification has been stored
    expect(notificationResponse.statusCode, equals(HttpStatus.ok));
    expect(notificationResponse.data['notifications'].length > 0, isTrue);
  });

  test('didcomm notification', () async {
    final keyPair = await aliceWallet.generateKey(keyId: "m/44'/60'/0'/5");

    final didManager = DidKeyManager(
      store: InMemoryDidStore(),
      wallet: aliceWallet,
    );

    await didManager.addVerificationMethod(keyPair.id);

    final didDoc = await didManager.getDidDocument();
    final mediatorDid = getEnv('MEDIATOR_DID');

    final sdk = MeetingPlaceMediatorSDK(
      mediatorDid: mediatorDid,
      didResolver: CachedDidResolver(),
    );

    await sdk.updateAcl(
      ownerDidManager: didManager,
      acl: AccessListAdd(
          ownerDid: didDoc.id, granteeDids: [getEnv('CONTROL_PLANE_DID')]),
      mediatorDid: mediatorDid,
    );

    final completer = Completer<void>();
    final channel = await sdk.subscribeToMessages(
      didManager,
      mediatorDid: mediatorDid,
    );

    final expectedMessageType =
        '${getEnv('CONTROL_PLANE_DID')}/mpx/control-plane/invitation-accept';

    channel.listen((message) {
      if (message.type.toString() == expectedMessageType) {
        completer.complete();
      }
    });

    final deviceToken = '$mediatorDid::${didDoc.id}';
    final platformType = PlatformType.DIDCOMM;

    await dio.post(
      '$apiEndpoint/v1/register-device',
      data: RegisterDeviceRequest(
        deviceToken: deviceToken,
        platformType: platformType,
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    final registerOfferResponse = await dio.post(
      '$apiEndpoint/v1/register-offer',
      data: getRegisterOfferRequestMock(
        deviceToken: deviceToken,
        platformType: platformType,
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': aliceAccessToken,
      }),
    );

    await dio.post(
      '$apiEndpoint/v1/accept-offer',
      data: getAcceptOfferRequest(
        did: BobDevice.offerAcceptanceDid,
        deviceToken: BobDevice.deviceToken,
        platformType: BobDevice.platformType,
        mnemonic: registerOfferResponse.data['mnemonic'],
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': bobAccessToken,
      }),
    );

    await dio.post(
      '$apiEndpoint/v1/notify-acceptance',
      data: NotifyAcceptanceRequest(
        did: BobDevice.offerAcceptanceDid,
        offerLink: registerOfferResponse.data['offerLink'],
        mnemonic: registerOfferResponse.data['mnemonic'],
        senderInfo: 'Anonymous',
      ).toJson(),
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
        'authorization': bobAccessToken,
      }),
    );

    await completer.future;
  },
      skip:
          '''Doesnt work on local server instance because mediator cant resolve did:web document of the server''');
}
