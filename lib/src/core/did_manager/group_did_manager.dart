import 'package:ssi/ssi.dart';

abstract interface class GroupDidManager {
  Future<DidDocument> createDid(String offerLink);
  Future<DidManager> get(String groupId);
  Future<void> removeKeys(String groupId);
}
