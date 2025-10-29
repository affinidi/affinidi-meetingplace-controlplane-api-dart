import 'package:ssi/ssi.dart';
import 'package:http/http.dart' as http;

/// A DID resolver that supports the `did:local` method.
/// Enables the server to operate in a local environment.
class LocalDidResolver implements DidResolver {
  LocalDidResolver({this.resolverAddress});
  final String? resolverAddress;

  @override
  Future<DidDocument> resolveDid(String did) async {
    if (did.startsWith('did:local')) {
      return _resolveLocalDid(did);
    }

    final didDocument = await UniversalDIDResolver(
      resolverAddress: resolverAddress,
    ).resolveDid(did);

    return didDocument;
  }

  Future<DidDocument> _resolveLocalDid(String did) async {
    var port = did.split(':').last;
    var res = await http
        .get(Uri.parse('http://localhost:$port/.well-known/did.json'));
    if (res.statusCode == 200) {
      return DidDocument.fromJson(res.body);
    } else {
      throw Exception('Bad status code ${res.statusCode}');
    }
  }
}
