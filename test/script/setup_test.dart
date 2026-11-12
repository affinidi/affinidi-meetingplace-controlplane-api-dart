import 'package:test/test.dart';

import '../../script/setup.dart';

void main() {
  const didWeb = 'did:web:example.com';

  Map<String, dynamic> verificationMethod(String fragment, String? crv) => {
    'id': '$didWeb#$fragment',
    'type': 'JsonWebKey2020',
    'controller': didWeb,
    if (crv != null) 'publicKeyJwk': {'crv': crv},
  };

  Map<String, dynamic> buildDidDocument(List<Map<String, dynamic>> jwks) =>
      generateDidDocument(
        jwks: jwks,
        didWeb: didWeb,
        serviceEndpoint: 'https://example.com/v1',
      );

  group('generateDidDocument keyAgreement', () {
    test('includes only key agreement curves', () {
      final didDocument = buildDidDocument([
        verificationMethod('1', 'P-256'),
        verificationMethod('2', 'secp256k1'),
        verificationMethod('3', 'Ed25519'),
        verificationMethod('4', 'X25519'),
        verificationMethod('5', 'Ed448'),
      ]);

      expect(didDocument['keyAgreement'], [
        '$didWeb#1',
        '$didWeb#2',
        '$didWeb#4',
      ]);
    });

    test('keeps every key in authentication and assertionMethod', () {
      final didDocument = buildDidDocument([
        verificationMethod('1', 'P-256'),
        verificationMethod('2', 'Ed25519'),
      ]);

      final allIds = ['$didWeb#1', '$didWeb#2'];
      expect(didDocument['authentication'], allIds);
      expect(didDocument['assertionMethod'], allIds);
    });

    test('skips entries without publicKeyJwk', () {
      final didDocument = buildDidDocument([
        verificationMethod('1', null),
        verificationMethod('2', 'P-256'),
      ]);

      expect(didDocument['keyAgreement'], ['$didWeb#2']);
    });
  });

  group('updateKeyAgreement', () {
    test('removes signing-only curves from an existing DID document', () {
      final verificationMethods = [
        verificationMethod('1', 'P-256'),
        verificationMethod('2', 'secp256k1'),
        verificationMethod('3', 'Ed25519'),
      ];
      final allIds = ['$didWeb#1', '$didWeb#2', '$didWeb#3'];
      final existingDidDocument = {
        'id': didWeb,
        'verificationMethod': verificationMethods,
        'authentication': allIds,
        'assertionMethod': allIds,
        'keyAgreement': allIds,
      };

      final updated = updateKeyAgreement(existingDidDocument);

      expect(updated['keyAgreement'], ['$didWeb#1', '$didWeb#2']);
      expect(updated['verificationMethod'], verificationMethods);
      expect(updated['authentication'], allIds);
      expect(updated['assertionMethod'], allIds);
    });

    test('throws when verificationMethod is missing', () {
      expect(
        () => updateKeyAgreement({'id': didWeb}),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
