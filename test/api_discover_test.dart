import 'dart:io';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:meeting_place_control_plane_api/src/core/config/env_config.dart';

void main() {
  final apiEndpoint = getEnv('API_ENDPOINT');
  final dio = Dio();

  test('#discovery: success', () async {
    final response = await dio.get('$apiEndpoint/discover');
    expect(response.statusCode, equals(HttpStatus.ok));
    expect(response.data, equals(getEnv('CONTROL_PLANE_DID')));
  });
}
