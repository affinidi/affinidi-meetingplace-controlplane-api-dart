import 'package:json_annotation/json_annotation.dart';

enum Transport {
  @JsonValue('didcomm')
  didcomm('didcomm'),

  @JsonValue('matrix')
  matrix('matrix');

  const Transport(this.value);

  final String value;
}
