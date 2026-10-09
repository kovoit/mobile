// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VehicleDto _$VehicleDtoFromJson(Map<String, dynamic> json) => VehicleDto(
  type: json['type'] as String,
  marque: json['marque'] as String,
  modele: json['modele'] as String,
  couleur: json['couleur'] as String,
  immatriculation: json['immatriculation'] as String,
  nbPlaces: (json['nb_places'] as num).toInt(),
  statutVerification: json['statut_verification'] as String?,
);

Map<String, dynamic> _$VehicleDtoToJson(VehicleDto instance) =>
    <String, dynamic>{
      'type': instance.type,
      'marque': instance.marque,
      'modele': instance.modele,
      'couleur': instance.couleur,
      'immatriculation': instance.immatriculation,
      'nb_places': instance.nbPlaces,
      'statut_verification': ?instance.statutVerification,
    };
