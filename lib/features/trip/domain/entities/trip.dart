import '../../../vehicle/domain/entities/vehicle.dart';
import 'geo_place.dart';

/// Profil public du conducteur, tel que calculé par le backend (note, fiabilité).
class TripDriver {
  const TripDriver({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.verifie,
    this.photoUrl,
    this.note,
    this.fiabilite,
    this.nbTrajets = 0,
  });

  final int id;
  final String prenom;
  final String nom;
  final String? photoUrl;
  final bool verifie;

  /// Moyenne sur 5, `null` tant qu'aucune note.
  final double? note;

  /// Taux de fiabilité en %, calculé par le backend (PRD §11).
  final int? fiabilite;
  final int nbTrajets;

  String get nomComplet => '$prenom $nom'.trim();
}

/// Véhicule tel qu'affiché au passager avant la prise en charge (photo + immatriculation).
class TripVehicle {
  const TripVehicle({
    required this.type,
    required this.marque,
    required this.modele,
    required this.couleur,
    required this.immatriculation,
    this.photoUrl,
  });

  final VehicleType type;
  final String marque;
  final String modele;
  final String couleur;
  final String immatriculation;
  final String? photoUrl;

  String get label => '$marque $modele'.trim();
}

class PickupPoint {
  const PickupPoint({required this.id, required this.ordre, required this.place});

  final int id;
  final int ordre;
  final GeoPlace place;
}

/// Trajet publié. Prix, frais, places et distances sont fournis par l'API : aucun calcul côté app.
class Trip {
  const Trip({
    required this.id,
    required this.driver,
    required this.vehicle,
    required this.depart,
    required this.arrivee,
    required this.pickupPoints,
    required this.departureAt,
    required this.placesRestantes,
    required this.prixPlace,
    this.fraisService = 0,
    this.prixTotal,
    this.estimatedArrivalAt,
    this.matchedPickupId,
    this.walkingDistanceKm,
  });

  final int id;
  final TripDriver driver;
  final TripVehicle vehicle;
  final GeoPlace depart;
  final GeoPlace arrivee;
  final List<PickupPoint> pickupPoints;
  final DateTime departureAt;
  final DateTime? estimatedArrivalAt;
  final int placesRestantes;
  final int prixPlace;
  final int fraisService;

  /// Total à payer pour les places demandées, calculé par le backend (jamais recalculé ici).
  final int? prixTotal;

  /// Point de prise en charge retenu pour le passager (fixé par le backend).
  final int? matchedPickupId;

  /// Distance de marche jusqu'au point retenu (renvoyée par la recherche uniquement).
  final double? walkingDistanceKm;

  PickupPoint? get matchedPickup =>
      pickupPoints.where((p) => p.id == matchedPickupId).firstOrNull ?? pickupPoints.firstOrNull;
}
