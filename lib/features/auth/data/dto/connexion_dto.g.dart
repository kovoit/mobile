// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connexion_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConnexionDto _$ConnexionDtoFromJson(Map<String, dynamic> json) => ConnexionDto(
  utilisateur: ProfilDto.fromJson(json['utilisateur'] as Map<String, dynamic>),
  access: json['access'] as String,
  refresh: json['refresh'] as String,
  nouveauCompte: json['nouveau_compte'] as bool? ?? false,
);
