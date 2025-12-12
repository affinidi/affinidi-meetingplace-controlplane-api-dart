import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';

import 'middleware/auth.dart';

import '../api/accept_offer/route.dart';
import '../api/accept_offer_group/route.dart';
import '../api/check_offer_phrase/route.dart';
import '../api/application_facade.dart';
import '../api/create_oob/route.dart';
import '../api/delete_pending_notifications/route.dart';
import '../api/deregister_notification/route.dart';
import '../api/discovery/route.dart';
import '../api/get_oob/route.dart';
import '../api/group_add_member/route.dart';
import '../api/group_delete/route.dart';
import '../api/group_member_deregister/route.dart';
import '../api/group_send_message/route.dart';
import '../api/notify_acceptance/route.dart';
import '../api/notify_acceptance_group/route.dart';
import '../api/notify_outreach/route.dart';
import '../api/register_device/route.dart';
import '../api/register_offer_group/route.dart';
import '../core/web_manager/did_document_manager.dart';
import '../api/finalise_acceptance/route.dart';
import '../api/auth_authenticate/route.dart';
import '../api/auth_challenge/route.dart';
import '../api/get_pending_notifications/route.dart';
import '../api/notify_channel/route.dart';
import '../api/register_notification/route.dart';
import '../api/deregister_offer/route.dart';
import '../api/query_offer/route.dart';
import '../api/register_offer/route.dart';

publicPipeline(handler, ApplicationFacade facade) {
  return Pipeline().addHandler((Request req) => handler(req, facade));
}

privatePipeline(handler, ApplicationFacade facade) {
  return Pipeline()
      .addMiddleware(authorize(facade.config.logger))
      .addHandler((Request req) => handler(req, facade));
}

Router createRouter(ApplicationFacade facade) {
  return Router()
    ..get('/', _staticHandler())
    ..get(
      '/.well-known/did.json',
      (Request req) => _didHandler(req, facade.config.didDocumentManager),
    )
    ..get('/asset/<imageName>', _assertImageHandler)
    ..get('/discover', publicPipeline(discoverApi, facade))
    // authentication routes
    ..post('/v1/authenticate', publicPipeline(authAuthenticate, facade))
    ..post('/v1/authenticate/challenge', publicPipeline(authChallenge, facade))
    // offer routes
    ..post('/v1/register-offer', privatePipeline(registerOffer, facade))
    ..post(
      '/v1/register-offer-group',
      privatePipeline(registerOfferGroup, facade),
    )
    ..post('/v1/deregister-offer', privatePipeline(deregisterOffer, facade))
    ..post('/v1/query-offer', privatePipeline(queryOffer, facade))
    ..post('/v1/accept-offer', privatePipeline(acceptOffer, facade))
    ..post('/v1/accept-offer-group', privatePipeline(acceptOfferGroup, facade))
    ..post('/v1/check-offer-phrase', privatePipeline(checkOfferPhrase, facade))
    // acceptance routes
    ..post(
      '/v1/finalise-acceptance',
      privatePipeline(finaliseAcceptance, facade),
    )
    // device routes
    ..post('/v1/register-device', privatePipeline(registerDevice, facade))
    // notification routes
    ..post(
      '/v1/notifications',
      privatePipeline(getPendingNotifications, facade),
    )
    ..post(
      '/v1/delete-notifications',
      privatePipeline(deletePendingNotifications, facade),
    )
    ..post(
      '/v1/register-notification',
      privatePipeline(registerNotification, facade),
    )
    ..post('/v1/notify-channel', privatePipeline(notifyChannel, facade))
    ..post('/v1/notify-acceptance', privatePipeline(notifyAcceptance, facade))
    ..post(
      '/v1/notify-acceptance-group',
      privatePipeline(notifyAcceptanceGroup, facade),
    )
    ..post(
      '/v1/deregister-notification',
      privatePipeline(deregisterNotification, facade),
    )
    // group routes
    ..post('/v1/group-add-member', privatePipeline(groupAddMember, facade))
    ..post('/v1/group-delete', privatePipeline(groupDelete, facade))
    ..post(
      '/v1/group-member-deregister',
      privatePipeline(groupDeregisterMember, facade),
    )
    ..post('/v1/group-send-message', privatePipeline(groupSendMessage, facade))
    // outreach
    ..post('/v1/notify-outreach', privatePipeline(notifyOutreach, facade))
    // oob
    ..post('/v1/create-oob', publicPipeline(createOob, facade))
    ..get('/v1/oob/<id>', publicPipeline(getOob, facade));
}

_staticHandler() {
  return createStaticHandler('static', defaultDocument: 'index.html');
}

_assertImageHandler(Request request, String imageName) async {
  var imagePath = 'static/$imageName';

  var file = File(imagePath);
  if (await file.exists()) {
    var bytes = await file.readAsBytes();
    return Response.ok(
      bytes,
      headers: {HttpHeaders.contentTypeHeader: 'image/svg+xml'},
    );
  } else {
    return Response.notFound('Image not found');
  }
}

_didHandler(Request request, DidDocumentManager didDocumentManager) async {
  final didDocument = await didDocumentManager.getDidDocument();
  final bytes = utf8.encode(jsonEncode(didDocument.toJson()));

  return Response.ok(
    bytes,
    headers: {HttpHeaders.contentTypeHeader: 'application/json'},
  );
}
