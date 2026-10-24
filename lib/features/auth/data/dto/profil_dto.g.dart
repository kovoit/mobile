// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profil_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfilDto _$ProfilDtoFromJson(Map<String, dynamic> json) => ProfilDto(
  id: json['id'] as String,
  email: json['email'] as String,
  telephone: json['telephone'] as String? ?? '',
  nom: json['nom'] as String? ?? '',
  prenom: json['prenom'] as String? ?? '',
  photo: json['photo'] as String?,
  emailVerifie: json['email_verifie'] as bool? ?? false,
  modeActif: json['mode_actif'] as String?,
  statutCompte: json['statut_compte'] as String?,
  suspenduJusquAu: json['suspendu_jusqu_au'] == null
      ? null
      : DateTime.parse(json['suspendu_jusqu_au'] as String),
  profilComplet: json['profil_complet'] as bool? ?? false,
  cguAcceptees: json['cgu_acceptees'] as bool? ?? true,
  cguUrl:
      json['cgu_url'] as String? ??
      'https://kovoittg.com/conditions-utilisation/',
  kyc: json['kyc'] as Map<String, dynamic>? ?? const {},
  etat: json['etat'] as Map<String, dynamic>? ?? const {},
);
