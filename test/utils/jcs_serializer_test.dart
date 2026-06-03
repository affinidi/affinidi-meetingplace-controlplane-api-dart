import 'dart:convert';

import 'package:meeting_place_control_plane_api/src/utils/jcs_serializer.dart';
import 'package:test/test.dart';

void main() {
  group('JcsSerializer', () {
    test('serializes nested objects with canonical key ordering', () {
      final input = {
        'z': 3,
        'a': {'b': 2, 'a': 1},
        'arr': [
          {'d': 4, 'c': 3},
          'value',
        ],
      };

      final serialized = jcsSerializer.serialize(input);

      expect(
        serialized,
        '{"a":{"a":1,"b":2},"arr":[{"c":3,"d":4},"value"],"z":3}',
      );
      expect(jsonDecode(serialized), jcsSerializer.canonicalize(input));
    });

    test('serializes doubles canonically and UTF-8 helpers match', () {
      final value = {'b': 0.0, 'a': 1.0, 'c': 1.25};

      final serialized = jcsSerializer.serializeObject(value);

      expect(serialized, '{"a":1,"b":0,"c":1.25}');
      expect(utf8.decode(jcsSerializer.serializeToUtf8(value)), serialized);
      expect(
        utf8.decode(jcsSerializer.serializeObjectToUtf8(value)),
        serialized,
      );
    });

    test('rejects lone surrogate code units', () {
      expect(
        () => jcsSerializer.serialize('\uD800'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects integers outside IEEE 754 exact range', () {
      expect(
        () => jcsSerializer.serialize(9007199254740993),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects non-finite doubles', () {
      expect(
        () => jcsSerializer.serialize(double.nan),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => jcsSerializer.serialize(double.infinity),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
