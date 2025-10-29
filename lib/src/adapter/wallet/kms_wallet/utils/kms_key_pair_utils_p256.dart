import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/pointycastle.dart';
import 'package:elliptic/elliptic.dart' as ec;

class KmsKeyPairUtilsP256 {
  static Uint8List uncompressPublicKey(Uint8List key) {
    // Already uncompressed?
    if (key.length == 65 && key[0] == 0x04) return key;

    // Must be compressed (33 bytes, prefix 0x02 or 0x03)
    if (key.length != 33 || !(key[0] == 0x02 || key[0] == 0x03)) {
      throw ArgumentError(
          'Key must be 33-byte compressed or 65-byte uncompressed.');
    }

    // convert to hex string (no 0x prefix)
    final hex = key.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    // choose curve (secp256k1 example)
    final curve = ec.getP256(); // or getS256()

    // decode using PublicKey.fromHex — it auto-detects compressed format
    final pub = ec.PublicKey.fromHex(curve, hex);

    final x = pub.X;
    final y = pub.Y;

    final xBytes = _bigIntToBytes(x, 32);
    final yBytes = _bigIntToBytes(y, 32);

    return Uint8List.fromList([0x04, ...xBytes, ...yBytes]);
  }

  static Uint8List _bigIntToBytes(BigInt n, int length) {
    if (n == BigInt.zero) return Uint8List(length);
    final bytes = <int>[];
    var v = n;
    while (v > BigInt.zero) {
      bytes.insert(0, (v & BigInt.from(0xff)).toInt());
      v = v >> 8;
    }
    // pad
    while (bytes.length < length) {
      bytes.insert(0, 0);
    }
    return Uint8List.fromList(bytes);
  }

  static Uint8List kmsP256ToEllipticFormat(
    Uint8List kmsPublicKeyDER, [
    String keySpec = 'ECC_NIST_P256',
  ]) {
    // Extract uncompressed key from DER format
    final uncompressed = _extractUncompressedKeyFromDER(kmsPublicKeyDER);

    // Step 2: Validate it's a valid uncompressed P-256 key
    if (uncompressed.length != 65 || uncompressed[0] != 0x04) {
      throw ArgumentError('Invalid P-256 key extracted from KMS DER format');
    }

    // Step 3: Compress the key
    return compressP256Key(uncompressed);
  }

  static Uint8List _extractUncompressedKeyFromDER(Uint8List derBytes) {
    // DER structure for EC public key:
    // 30 59 (SEQUENCE)
    //   30 13 (SEQUENCE - algorithm identifier)
    //     06 07 2a8648ce3d0201 (OID - ecPublicKey)
    //     06 08 2a8648ce3d030107 (OID - prime256v1 for P-256)
    //   03 42 00 (BIT STRING)
    //     04... (uncompressed point - 65 bytes starting with 0x04)

    // Look for bit string (0x03) followed by length, then 0x00, then 0x04
    for (int i = 0; i < derBytes.length - 66; i++) {
      if (derBytes[i] == 0x03 &&
          derBytes[i + 2] == 0x00 &&
          derBytes[i + 3] == 0x04) {
        // Found the bit string with uncompressed point
        final keyStart = i + 3; // Start at 0x04
        if (keyStart + 65 <= derBytes.length) {
          return derBytes.sublist(keyStart, keyStart + 65);
        }
      }
    }

    // Fallback: look for 0x04 prefix directly
    for (int i = 0; i < derBytes.length - 64; i++) {
      if (derBytes[i] == 0x04) {
        return derBytes.sublist(i, i + 65);
      }
    }

    throw ArgumentError(
        'Could not find uncompressed EC public key in DER data');
  }

  static Uint8List compressP256Key(Uint8List uncompressedKey) {
    if (uncompressedKey.length != 65 || uncompressedKey[0] != 0x04) {
      throw ArgumentError(
          'Invalid uncompressed P-256 key format. Expected 65 bytes starting with 0x04');
    }

    // Split into x and y coordinates (32 bytes each)
    final x = uncompressedKey.sublist(1, 33);
    final y = uncompressedKey.sublist(33, 65);

    // Check if y is even or odd (look at least significant bit)
    final yIsEven = (y[31] & 0x01) == 0;

    // Create compressed key: prefix (0x02 for even y, 0x03 for odd y) + x coordinate
    final compressed = Uint8List(33);
    compressed[0] = yIsEven ? 0x02 : 0x03;
    compressed.setRange(1, 33, x);

    return compressed;
  }

  static String formatForAWSKMS(Uint8List uncompressedKey) {
    if (uncompressedKey.length != 65 || uncompressedKey[0] != 0x04) {
      throw ArgumentError(
          'Invalid uncompressed key format. Must be 65 bytes starting with 0x04');
    }

    // Extract coordinates
    final xCoord = uncompressedKey.sublist(1, 33);
    final yCoord = uncompressedKey.sublist(33, 65);

    // Create DER-encoded SubjectPublicKeyInfo for secp256k1
    final derEncoded = _createDEREncodedKey(xCoord, yCoord);

    // Base64 encode for AWS KMS
    return base64Encode(derEncoded);
  }

  static Uint8List _createDEREncodedKey(Uint8List xCoord, Uint8List yCoord) {
    // secp256k1 OID: 1.3.132.0.10
    final p256OID = Uint8List.fromList(
        [0x06, 0x08, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x03, 0x01, 0x07]);

    // EC Public Key OID: 1.2.840.10045.2.1
    final ecPublicKeyOID = Uint8List.fromList(
        [0x06, 0x07, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x02, 0x01]);

    // Reconstruct uncompressed point
    final publicKeyPoint = Uint8List(65);
    publicKeyPoint[0] = 0x04;
    publicKeyPoint.setRange(1, 33, xCoord);
    publicKeyPoint.setRange(33, 65, yCoord);

    // Build DER structure
    final algorithmIdentifier = _encodeDERSequence([ecPublicKeyOID, p256OID]);

    final publicKeyBitString = _encodeDERBitString(publicKeyPoint);

    return _encodeDERSequence([algorithmIdentifier, publicKeyBitString]);
  }

  static Uint8List _encodeDERSequence(List<Uint8List> elements) {
    final content = _concatenateBytes(elements);
    return _encodeDERTLV(0x30, content);
  }

  static Uint8List _encodeDERBitString(Uint8List data) {
    final content = Uint8List(data.length + 1);
    content[0] = 0x00; // No unused bits
    content.setRange(1, content.length, data);
    return _encodeDERTLV(0x03, content);
  }

  static Uint8List _concatenateBytes(List<Uint8List> arrays) {
    final totalLength = arrays.fold(0, (sum, array) => sum + array.length);
    final result = Uint8List(totalLength);

    int offset = 0;
    for (final array in arrays) {
      result.setRange(offset, offset + array.length, array);
      offset += array.length;
    }

    return result;
  }

  static Uint8List _encodeDERTLV(int tag, Uint8List content) {
    final length = content.length;
    final result = <int>[tag];

    if (length < 0x80) {
      result.add(length);
    } else if (length <= 0xFF) {
      result.addAll([0x81, length]);
    } else if (length <= 0xFFFF) {
      result.addAll([0x82, length >> 8, length & 0xFF]);
    } else {
      throw ArgumentError('Content too long for DER encoding');
    }

    result.addAll(content);
    return Uint8List.fromList(result);
  }

  Uint8List derFormatDecode(Uint8List derSignature, int keySizeBytes) {
    var asn1 = ASN1Parser(derSignature);
    ASN1Sequence seq = asn1.nextObject() as ASN1Sequence;

    ASN1Integer r = seq.elements![0] as ASN1Integer;
    ASN1Integer s = seq.elements![1] as ASN1Integer;

    Uint8List rBytes = _integerToBytes(r.integer!, keySizeBytes);
    Uint8List sBytes = _integerToBytes(s.integer!, keySizeBytes);

    return Uint8List.fromList([...rBytes, ...sBytes]);
  }

  Uint8List _integerToBytes(BigInt value, int length) {
    var bytes =
        value.toUnsigned(8 * length).toRadixString(16).padLeft(length * 2, '0');
    return Uint8List.fromList([
      for (int i = 0; i < bytes.length; i += 2)
        int.parse(bytes.substring(i, i + 2), radix: 16)
    ]);
  }

  static Uint8List normalizeKeyInput(dynamic input) {
    if (input is Uint8List) {
      return input;
    } else if (input is List<int>) {
      return Uint8List.fromList(input);
    } else if (input is String) {
      // Remove common prefixes and whitespace
      String cleaned = input
          .replaceAll('0x', '')
          .replaceAll(' ', '')
          .replaceAll('\n', '')
          .replaceAll('\t', '');

      return hexToBytes(cleaned);
    } else {
      throw ArgumentError('Unsupported input type: ${input.runtimeType}');
    }
  }

  static Uint8List hexToBytes(String hex) {
    if (hex.length % 2 != 0) {
      hex = '0$hex';
    }

    final bytes = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }

    return Uint8List.fromList(bytes);
  }
}
