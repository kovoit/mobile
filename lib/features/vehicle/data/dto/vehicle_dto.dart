import 'package:json_annotation/json_annotation.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/vehicle.dart';

part 'vehicle_dto.g.dart';

/// Objet `vehicule` de l'API (voir docs/api/vehicle.md).
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class VehicleDto {
  const VehicleDto({
    required this.type,
    required this.marque,
    required this.modele,
    required this.couleur,
    required this.immatriculation,
    required this.nbPlaces,
    this.statutVerification,
  });

  factory VehicleDto.fromJson(Map<String, dynamic> json) => _$VehicleDtoFromJson(json);

  factory VehicleDto.fromEntity(Vehicle vehicle) => VehicleDto(
        type: vehicle.type.apiValue,
        marque: vehicle.marque,
        modele: vehicle.modele,
        couleur: vehicle.couleur,
        immatriculation: vehicle.immatriculation,
        nbPlaces: vehicle.nbPlaces,
      );

  final String type;
  final String marque;
  final String modele;
  final String couleur;
  final String immatriculation;
  final int nbPlaces;

  /// Lecture seule (renvoyé par l'API, jamais envoyé).
  final String? statutVerification;

  Map<String, dynamic> toJson() => _$VehicleDtoToJson(this);

  Vehicle toEntity() => Vehicle(
        type: VehicleType.fromApi(type),
        marque: marque,
        modele: modele,
        couleur: couleur,
        immatriculation: immatriculation,
        nbPlaces: nbPlaces,
        statutVerification: KycStatus.fromApi(statutVerification ?? 'en_attente'),
      );
}
