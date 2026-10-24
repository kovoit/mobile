// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VehicleDto _$VehicleDtoFromJson(Map<String, dynamic> json) => VehicleDto(
  typeVehicule: json['type_vehicule'] as String,
  marque: json['marque'] as String,
  modele: json['modele'] as String,
  couleur: json['couleur'] as String,
  immatriculation: json['immatriculation'] as String,
  nbPlaces: (json['nb_places'] as num).toInt(),
  id: json['id'] as String?,
  consommationL100km: json['consommation_l_100km'] as String?,
);

Map<String, dynamic> _$VehicleDtoToJson(VehicleDto instance) =>
    <String, dynamic>{
      'id': ?instance.id,
      'type_vehicule': instance.typeVehicule,
      'marque': instance.marque,
      'modele': instance.modele,
      'couleur': instance.couleur,
      'immatriculation': instance.immatriculation,
      'nb_places': instance.nbPlaces,
      'consommation_l_100km': instance.consommationL100km,
    };
