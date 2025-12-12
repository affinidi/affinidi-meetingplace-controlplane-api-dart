import 'dart:typed_data';

import 'package:pointycastle/pointycastle.dart';

class DerDecoder {
  static Uint8List convert(Uint8List derSignature, int keySizeBytes) {
    var asn1 = ASN1Parser(derSignature);
    ASN1Sequence seq = asn1.nextObject() as ASN1Sequence;

    ASN1Integer r = seq.elements![0] as ASN1Integer;
    ASN1Integer s = seq.elements![1] as ASN1Integer;

    Uint8List rBytes = _integerToBytes(r.integer!, keySizeBytes);
    Uint8List sBytes = _integerToBytes(s.integer!, keySizeBytes);

    return Uint8List.fromList([...rBytes, ...sBytes]);
  }

  static Uint8List _integerToBytes(BigInt value, int length) {
    var bytes = value
        .toUnsigned(8 * length)
        .toRadixString(16)
        .padLeft(length * 2, '0');
    return Uint8List.fromList([
      for (int i = 0; i < bytes.length; i += 2)
        int.parse(bytes.substring(i, i + 2), radix: 16),
    ]);
  }
}
