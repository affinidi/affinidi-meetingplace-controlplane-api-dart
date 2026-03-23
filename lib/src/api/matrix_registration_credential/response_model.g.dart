// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_model.dart';

// ***************************************************************************
// JsonSerializableGenerator
// ***************************************************************************

MatrixRegistrationCredentialResponse
_$MatrixRegistrationCredentialResponseFromJson(Map<String, dynamic> json) =>
    MatrixRegistrationCredentialResponse(
      credential: json['credential'] as String,
      did: json['did'] as String,
    );

Map<String, dynamic> _$MatrixRegistrationCredentialResponseToJson(
  MatrixRegistrationCredentialResponse instance,
) => <String, dynamic>{'credential': instance.credential, 'did': instance.did};
