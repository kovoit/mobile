import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/vehicle.dart';

part 'vehicle_dto.g.dart';

/// Véhicule (backend : VehiculeSerializer). La vérification passe par le KYC conducteur.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class VehicleDto {
  const VehicleDto({
    required this.typeVehicule,
    required this.marque,
    required this.modele,
    required this.couleur,
    required this.immatriculation,
    required this.nbPlaces,
    this.id,
  });

  factory VehicleDto.fromJson(Map<String, dynamic> json) => _$VehicleDtoFromJson(json);

  factory VehicleDto.fromEntity(Vehicle vehicle) => VehicleDto(
        id: vehicle.id,
        typeVehicule: vehicle.type.apiValue,
        marque: vehicle.marque,
        modele: vehicle.modele,
        couleur: vehicle.couleur,
        immatriculation: vehicle.immatriculation,
        nbPlaces: vehicle.nbPlaces,
      );

  /// Lecture seule (attribué par le backend).
  final String? id;
  final String typeVehicule;
  final String marque;
  final String modele;
  final String couleur;
  final String immatriculation;
  final int nbPlaces;

  Map<String, dynamic> toJson() => _$VehicleDtoToJson(this);

  /// Corps d'une création ou d'une modification (sans l'identifiant).
  Map<String, dynamic> toRequest() => toJson()..remove('id');

  Vehicle toEntity() => Vehicle(
        id: id,
        type: VehicleType.fromApi(typeVehicule),
        marque: marque,
        modele: modele,
        couleur: couleur,
        immatriculation: immatriculation,
        nbPlaces: nbPlaces,
      );
}
