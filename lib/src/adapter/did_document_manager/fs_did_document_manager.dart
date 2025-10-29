import 'dart:convert';
import 'dart:io';

import 'package:ssi/ssi.dart';
import '../../core/config/env_config.dart';
import '../../core/web_manager/did_document_manager.dart';

class FsDidDocumentManager implements DidDocumentManager {
  @override
  Future<DidDocument> getDidDocument() {
    final file = File('${Directory.current.path}/${getEnv('DID_DOCUMENT')}');
    final json = jsonDecode(file.readAsStringSync());
    return Future.value(DidDocument.fromJson(json));
  }
}
