import 'dart:convert';
import 'dart:typed_data';

import 'package:base_codecs/base_codecs.dart';
import 'package:elliptic/elliptic.dart' as elliptic;
import 'package:ssi/ssi.dart';

/// Encode [input] as base64 URL encoding without adding padding
String base64UrlNoPadEncode(Uint8List input) {
  final b64Padded = base64UrlEncode(input);

  var lastNoPadIndex = b64Padded.length - 1;
  while (lastNoPadIndex > 0 && b64Padded[lastNoPadIndex] == '=') {
    lastNoPadIndex--;
  }

  return b64Padded.substring(0, lastNoPadIndex + 1);
}

/// Converts a multikey to a JWK map.
Map<String, String> multiKeyToJwk(Uint8List multikey) {
  final indicator = multikey.sublist(0, 2);
  final key = multikey.sublist(2);

  final indicatorHex = hex.encode(indicator);

  // see https://www.w3.org/TR/cid-1.0/#Multikey for indicators
  // FIXME add validations for length
  var jwk = <String, String>{};
  if (indicatorHex == 'ED01') {
    jwk['kty'] = 'OKP';
    jwk['crv'] = 'Ed25519';
    jwk['x'] = base64UrlNoPadEncode(key);
  } else if (indicatorHex == 'EC01') {
    jwk['kty'] = 'OKP';
    jwk['crv'] = 'X25519';
    jwk['x'] = base64UrlNoPadEncode(key);
  } else if (indicatorHex == '8024') {
    jwk['kty'] = 'EC';
    jwk['crv'] = 'P-256';
    final c = elliptic.getP256();
    final pub = c.compressedHexToPublicKey(hex.encode(key));
    jwk['x'] = base64UrlNoPadEncode(encodeBigInt(pub.X));
    jwk['y'] = base64UrlNoPadEncode(encodeBigInt(pub.Y));
  } else if (indicatorHex == 'E701') {
    jwk['kty'] = 'EC';
    jwk['crv'] = 'secp256k1';
    final c = elliptic.getSecp256k1();
    final pub = c.compressedHexToPublicKey(hex.encode(key));
    jwk['x'] = base64UrlNoPadEncode(encodeBigInt(pub.X));
    jwk['y'] = base64UrlNoPadEncode(encodeBigInt(pub.Y));
  } else if (indicatorHex == '8124') {
    jwk['kty'] = 'EC';
    jwk['crv'] = 'P-384';
    final c = elliptic.getP384();
    final pub = c.compressedHexToPublicKey(hex.encode(key));
    jwk['x'] = base64UrlNoPadEncode(encodeBigInt(pub.X));
    jwk['y'] = base64UrlNoPadEncode(encodeBigInt(pub.Y));
  } else if (indicatorHex == '8224') {
    jwk['kty'] = 'EC';
    jwk['crv'] = 'P-521';
    final c = elliptic.getP521();
    final pub = c.compressedHexToPublicKey(hex.encode(key));
    jwk['x'] = base64UrlNoPadEncode(encodeBigInt(pub.X));
    jwk['y'] = base64UrlNoPadEncode(encodeBigInt(pub.Y));
  } else {
    throw SsiException(
      message: 'Unsupported multicodec indicator 0x$indicatorHex',
      code: SsiExceptionType.invalidDidDocument.code,
    );
  }
  return jwk;
}

/// Converts a public key to a JWK map.
Map<String, String> keyToJwk(PublicKey publicKey) {
  final multikey = toMultikey(publicKey.bytes, publicKey.type);
  return multiKeyToJwk(multikey);
}

/// Supported multikey indicators.
enum MultiKeyIndicator {
  /// Indicator for X25519 keys.
  x25519(KeyType.x25519, [0xEC, 0x01]),

  /// Indicator for Ed25519 keys.
  ed25519(KeyType.ed25519, [0xED, 0x01]),

  /// Indicator for secp256k1 keys.
  secp256k1(KeyType.secp256k1, [0xE7, 0x01]),

  /// Indicator for P-256 keys.
  p256(KeyType.p256, [0x80, 0x24]),

  /// Indicator for P-384 keys.
  p384(KeyType.p384, [0x81, 0x24]),

  /// Indicator for P-521 keys.
  p521(KeyType.p521, [0x82, 0x24]);

  /// Creates a [MultiKeyIndicator] instance.
  const MultiKeyIndicator(this.keyType, this.indicator);

  /// The indicator bytes for the key type.
  final List<int> indicator;

  /// The key type.
  final KeyType keyType;
}

/// Returns a map of [KeyType] to [MultiKeyIndicator].
final Map<KeyType, MultiKeyIndicator> keyIndicators = _initKeyIndicatorsMap();

/// Initializes the map of [KeyType] to [MultiKeyIndicator].
Map<KeyType, MultiKeyIndicator> _initKeyIndicatorsMap() {
  final map = <KeyType, MultiKeyIndicator>{};
  for (final keyIndicator in MultiKeyIndicator.values) {
    map[keyIndicator.keyType] = keyIndicator;
  }
  return map;
}

/// Converts a public key and key type to a multikey [Uint8List].
Uint8List toMultikey(
  Uint8List pubKeyBytes,
  KeyType keyType,
) {
  if (!keyIndicators.containsKey(keyType)) {
    throw SsiException(
      message: 'toMultikey: $keyType not supported',
      code: SsiExceptionType.invalidKeyType.code,
    );
  }
  final indicator = keyIndicators[keyType]!;
  return Uint8List.fromList([...indicator.indicator, ...pubKeyBytes]);
}

/// The value 256 as a [BigInt].
final b256 = BigInt.from(256);

/// Encodes a [BigInt] to a [Uint8List].
Uint8List encodeBigInt(BigInt number) {
  // see https://github.com/dart-lang/sdk/issues/32803
  // Not handling negative numbers. Decide how you want to do that.
  var bytes = (number.bitLength + 7) >> 3;

  final result = Uint8List(bytes);
  for (var i = 0; i < bytes; i++) {
    result[bytes - 1 - i] = number.remainder(b256).toInt();
    number = number >> 8;
  }

  return result;
}
