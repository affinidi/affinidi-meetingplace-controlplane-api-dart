import 'dart:convert';

import 'package:aws_secretsmanager_api/secretsmanager-2017-10-17.dart';
import 'package:ssi/ssi.dart';
import 'package:aws_ssm_api/ssm-2014-11-06.dart' as ssm;
import '../../core/config/env_config.dart';
import '../../core/web_manager/did_document_manager.dart';

import '../aws_credentials_manager.dart';

class AwsSsmDidDocumentManager implements DidDocumentManager {
  AwsSsmDidDocumentManager._(
      {required String region, required AwsClientCredentials credentials})
      : _credentials = credentials,
        _provider = ssm.SSM(
          region: getEnv('AWS_REGION'),
          credentials: credentials,
        );

  final Map<String, dynamic> _inMemoryStorage = {};
  ssm.SSM _provider;
  ssm.AwsClientCredentials _credentials;

  static init() async {
    final credentials = await AwsCredentialsManager.getCredentials();

    final manager = AwsSsmDidDocumentManager._(
      region: getEnv('AWS_REGION'),
      credentials: credentials,
    );
    return manager;
  }

  @override
  Future<DidDocument> getDidDocument() async {
    final ssmParam = getEnv('DID_DOCUMENT');
    if (_inMemoryStorage.containsKey(ssmParam)) {
      return _toDidDocument(_inMemoryStorage[ssmParam]);
    }

    final client = await _getClient();
    final ssmParameter = await client.getParameter(name: ssmParam);
    final paramValue = ssmParameter.parameter?.value;

    if (paramValue == null) {
      throw Exception('SSM parameter $ssmParam not available');
    }

    final didDocument = _toDidDocument(paramValue);
    _inMemoryStorage[ssmParam] = paramValue;
    return Future.value(didDocument);
  }

  DidDocument _toDidDocument(String value) {
    final json = jsonDecode(value);
    return DidDocument.fromJson(json);
  }

  Future<ssm.SSM> _getClient() async {
    final refreshedCredentials =
        await AwsCredentialsManager.refreshCredentialsIfNeeded(_credentials);

    if (refreshedCredentials != null) {
      _credentials = refreshedCredentials;
      _provider = ssm.SSM(
        region: getEnv('AWS_REGION'),
        credentials: refreshedCredentials,
      );
    }
    return _provider;
  }
}
