// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserDto _$UserDtoFromJson(Map<String, dynamic> json) => UserDto(
  id: (json['id'] as num).toInt(),
  prenom: json['prenom'] as String,
  nom: json['nom'] as String,
  email: json['email'] as String,
  telephone: json['telephone'] as String?,
  telephoneVerifie: json['telephone_verifie'] as bool? ?? false,
  photo: json['photo'] as String?,
  modeActif: json['mode_actif'] as String?,
  statutCompte: json['statut_compte'] as String?,
  suspenduJusquAu: json['suspendu_jusqu_au'] == null
      ? null
      : DateTime.parse(json['suspendu_jusqu_au'] as String),
  kycPassager: json['kyc_passager'] as String?,
  kycConducteur: json['kyc_conducteur'] as String?,
  vehiculeDeclare: json['vehicule_declare'] as bool? ?? false,
);

Map<String, dynamic> _$UserDtoToJson(UserDto instance) => <String, dynamic>{
  'id': instance.id,
  'prenom': instance.prenom,
  'nom': instance.nom,
  'email': instance.email,
  'telephone': instance.telephone,
  'telephone_verifie': instance.telephoneVerifie,
  'photo': instance.photo,
  'mode_actif': instance.modeActif,
  'statut_compte': instance.statutCompte,
  'suspendu_jusqu_au': instance.suspenduJusquAu?.toIso8601String(),
  'kyc_passager': instance.kycPassager,
  'kyc_conducteur': instance.kycConducteur,
  'vehicule_declare': instance.vehiculeDeclare,
};
