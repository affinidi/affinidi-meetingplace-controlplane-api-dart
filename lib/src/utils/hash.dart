import 'dart:convert';
import 'package:crypto/crypto.dart';

String generateHashedId(String value, String secret) {
  return sha256.convert(utf8.encode("$value$secret")).toString();
}
