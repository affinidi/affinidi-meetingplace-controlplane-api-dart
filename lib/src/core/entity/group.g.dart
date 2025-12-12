// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Group _$GroupFromJson(Map<String, dynamic> json) => Group(
  ttl: json['ttl'] == null ? null : DateTime.parse(json['ttl'] as String),
  id: json['id'] as String,
  offerLink: json['offerLink'] as String,
  groupDid: json['groupDid'] as String,
  conrollingDid: json['conrollingDid'] as String,
  name: json['name'] as String,
  mediatorDid: json['mediatorDid'] as String,
  createdBy: json['createdBy'] as String,
  modifiedBy: json['modifiedBy'] as String,
  status: $enumDecode(_$GroupStatusEnumMap, json['status']),
  seqNo: (json['seqNo'] as num).toInt(),
);

Map<String, dynamic> _$GroupToJson(Group instance) => <String, dynamic>{
  'ttl': instance.ttl?.toIso8601String(),
  'id': instance.id,
  'offerLink': instance.offerLink,
  'groupDid': instance.groupDid,
  'name': instance.name,
  'mediatorDid': instance.mediatorDid,
  'conrollingDid': instance.conrollingDid,
  'createdBy': instance.createdBy,
  'modifiedBy': instance.modifiedBy,
  'status': _$GroupStatusEnumMap[instance.status]!,
  'seqNo': instance.seqNo,
};

const _$GroupStatusEnumMap = {
  GroupStatus.created: 'CREATED',
  GroupStatus.deleted: 'DELETED',
};
