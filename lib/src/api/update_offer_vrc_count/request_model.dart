import 'package:json_annotation/json_annotation.dart';

part 'request_model.g.dart';

@JsonSerializable()
class UpdateOffersVrcCountRequest {
  UpdateOffersVrcCountRequest({required this.score, required this.offerLinks});

  factory UpdateOffersVrcCountRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateOffersVrcCountRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateOffersVrcCountRequestToJson(this);

  final int score;
  final List<String> offerLinks;
}
