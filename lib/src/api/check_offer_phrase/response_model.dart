import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'response_model.g.dart';

@JsonSerializable()
class CheckOfferPhraseResponse {
  CheckOfferPhraseResponse({required this.isInUse});
  final bool isInUse;

  @override
  String toString() =>
      JsonEncoder().convert(_$CheckOfferPhraseResponseToJson(this));
}
