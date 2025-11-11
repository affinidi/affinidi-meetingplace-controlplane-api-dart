import 'dart:io';

import 'package:shelf/shelf.dart';
import '../../core/config/env_config.dart';
import '../application_facade.dart';

Future<Response> discoverApi(Request request, ApplicationFacade facade) async {
  return Response.ok(
    getEnv('CONTROL_PLANE_DID'),
    headers: {HttpHeaders.contentTypeHeader: 'text/plain'},
  );
}
