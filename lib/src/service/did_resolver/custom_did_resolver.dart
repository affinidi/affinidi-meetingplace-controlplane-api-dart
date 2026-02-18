import 'package:ssi/ssi.dart';

class CustomDidResolver implements DidResolver {
  CustomDidResolver({this.resolverAddress});
  final String? resolverAddress;

  @override
  Future<DidDocument> resolveDid(String did) async {
    final didDocument = await UniversalDIDResolver(
      resolverAddress: resolverAddress,
    ).resolveDid(did);

    return didDocument;
  }
}
