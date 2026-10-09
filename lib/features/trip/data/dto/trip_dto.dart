import 'package:json_annotation/json_annotation.dart';

import '../../../vehicle/domain/entities/vehicle.dart';
import '../../domain/entities/geo_place.dart';
import '../../domain/entities/trip.dart';

part 'trip_dto.g.dart';

/// Objet `lieu` (docs/api/trips.md).
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class GeoPlaceDto {
  const GeoPlaceDto({required this.libelle, required this.lat, required this.lng, this.id, this.quartier, this.type});

  factory GeoPlaceDto.fromJson(Map<String, dynamic> json) => _$GeoPlaceDtoFromJson(json);

  factory GeoPlaceDto.fromEntity(GeoPlace place) => GeoPlaceDto(
        id: place.id,
        libelle: place.libelle,
        quartier: place.quartier,
        type: place.type.apiValue,
        lat: place.lat,
        lng: place.lng,
      );

  final int? id;
  final String libelle;
  final String? quartier;
  final String? type;
  final double lat;
  final double lng;

  Map<String, dynamic> toJson() => _$GeoPlaceDtoToJson(this);

  GeoPlace toEntity() => GeoPlace(
        id: id,
        libelle: libelle,
        quartier: quartier,
        type: GeoPlaceType.fromApi(type),
        lat: lat,
        lng: lng,
      );
}

@JsonSerializable(fieldRename: FieldRename.snake)
class TripDriverDto {
  const TripDriverDto({
    required this.id,
    required this.prenom,
    required this.nom,
    this.photo,
    this.verifie = false,
    this.note,
    this.fiabilite,
    this.nbTrajets = 0,
  });

  factory TripDriverDto.fromJson(Map<String, dynamic> json) => _$TripDriverDtoFromJson(json);

  final int id;
  final String prenom;
  final String nom;
  final String? photo;
  final bool verifie;
  final double? note;
  final int? fiabilite;
  final int nbTrajets;

  Map<String, dynamic> toJson() => _$TripDriverDtoToJson(this);

  TripDriver toEntity() => TripDriver(
        id: id,
        prenom: prenom,
        nom: nom,
        photoUrl: photo,
        verifie: verifie,
        note: note,
        fiabilite: fiabilite,
        nbTrajets: nbTrajets,
      );
}

@JsonSerializable(fieldRename: FieldRename.snake)
class TripVehicleDto {
  const TripVehicleDto({
    required this.type,
    required this.marque,
    required this.modele,
    required this.couleur,
    required this.immatriculation,
    this.photo,
  });

  factory TripVehicleDto.fromJson(Map<String, dynamic> json) => _$TripVehicleDtoFromJson(json);

  final String type;
  final String marque;
  final String modele;
  final String couleur;
  final String immatriculation;
  final String? photo;

  Map<String, dynamic> toJson() => _$TripVehicleDtoToJson(this);

  TripVehicle toEntity() => TripVehicle(
        type: VehicleType.fromApi(type),
        marque: marque,
        modele: modele,
        couleur: couleur,
        immatriculation: immatriculation,
        photoUrl: photo,
      );
}

@JsonSerializable(fieldRename: FieldRename.snake)
class PickupPointDto {
  const PickupPointDto({required this.id, required this.ordre, required this.libelle, required this.lat, required this.lng, this.quartier});

  factory PickupPointDto.fromJson(Map<String, dynamic> json) => _$PickupPointDtoFromJson(json);

  final int id;
  final int ordre;
  final String libelle;
  final String? quartier;
  final double lat;
  final double lng;

  Map<String, dynamic> toJson() => _$PickupPointDtoToJson(this);

  PickupPoint toEntity() => PickupPoint(
        id: id,
        ordre: ordre,
        place: GeoPlace(libelle: libelle, quartier: quartier, lat: lat, lng: lng, type: GeoPlaceType.carrefour),
      );
}

/// Objet `trajet_resume` (docs/api/trips.md).
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class TripDto {
  const TripDto({
    required this.id,
    required this.conducteur,
    required this.vehicule,
    required this.depart,
    required this.arrivee,
    required this.pointsPriseEnCharge,
    required this.departLe,
    required this.placesRestantes,
    required this.prixPlace,
    this.fraisService = 0,
    this.prixTotal,
    this.arriveeEstimeeLe,
    this.pointCorrespondantId,
    this.distanceMarcheKm,
  });

  factory TripDto.fromJson(Map<String, dynamic> json) => _$TripDtoFromJson(json);

  final int id;
  final TripDriverDto conducteur;
  final TripVehicleDto vehicule;
  final GeoPlaceDto depart;
  final GeoPlaceDto arrivee;
  final List<PickupPointDto> pointsPriseEnCharge;
  final DateTime departLe;
  final DateTime? arriveeEstimeeLe;
  final int placesRestantes;
  final int prixPlace;
  final int fraisService;
  final int? prixTotal;
  final int? pointCorrespondantId;
  final double? distanceMarcheKm;

  Map<String, dynamic> toJson() => _$TripDtoToJson(this);

  Trip toEntity() => Trip(
        id: id,
        driver: conducteur.toEntity(),
        vehicle: vehicule.toEntity(),
        depart: depart.toEntity(),
        arrivee: arrivee.toEntity(),
        pickupPoints: [for (final p in pointsPriseEnCharge) p.toEntity()]..sort((a, b) => a.ordre.compareTo(b.ordre)),
        departureAt: departLe,
        estimatedArrivalAt: arriveeEstimeeLe,
        placesRestantes: placesRestantes,
        prixPlace: prixPlace,
        fraisService: fraisService,
        prixTotal: prixTotal,
        matchedPickupId: pointCorrespondantId,
        walkingDistanceKm: distanceMarcheKm,
      );
}
