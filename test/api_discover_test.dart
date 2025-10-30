import 'dart:io';

import 'package:meeting_place_control_plane_api/src/core/config/env_config.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  final apiEndpoint = getEnv('API_ENDPOINT');
  final dio = Dio();

  test('#discovery: success', () async {
    final response = await dio.get(
      '$apiEndpoint/discover',
      options: Options(headers: {
        Headers.contentTypeHeader: 'application/json',
      }),
    );

    expect(response.statusCode, HttpStatus.ok);

    final payload = JWT.decode(response.data['token']);
    final payloadData = payload.payload['data'];

    expect(payload.issuer, getEnv('CONTROL_PLANE_DID'));
    expect(
      payloadData['type'],
      'https://affinidi.io/mpx/control-plane/registration',
    );

    expect(payloadData['from'], getEnv('CONTROL_PLANE_DID'));
    expect(payloadData['body'], {
      'httpApi': getEnv('API_ENDPOINT'),
      'httpApiVersion': 'v1',
    });
  });
}
