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
    this.nombreNotes = 0,
  });

  final String id;
  final String prenom;
  final String nom;
  final String? photoUrl;

  /// KYC conducteur vérifié par Kovoit.
  final bool verifie;

  /// Moyenne sur 5, `null` tant qu'aucune note.
  final double? note;

  /// Taux de fiabilité en %, calculé par le backend (PRD §8).
  final int? fiabilite;

  /// Nombre de notes reçues.
  final int nombreNotes;

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

  final String id;
  final int ordre;
  final GeoPlace place;
}

/// Ce que la réservation prendra sur le portefeuille, calculé par le backend pour le lecteur.
class PaymentPreview {
  const PaymentPreview({
    required this.montantTotal,
    required this.soldeDisponible,
    required this.complementAPayer,
    this.rechargeSuggeree = 0,
  });

  /// Prix + frais de service, en F CFA.
  final int montantTotal;
  final int soldeDisponible;

  /// Manque sur le portefeuille pour réserver (0 si le solde suffit).
  final int complementAPayer;

  /// Recharge à proposer : le complément, au moins la recharge minimale (fixée par Kovoit).
  final int rechargeSuggeree;
}

/// Trajet publié. Prix, frais, places et distances sont fournis par l'API : aucun calcul côté app.
/// Une réservation = une place (décision MVP).
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
    this.statut = 'publie',
    this.payment,
    this.matchedPickupId,
    this.walkingDistanceKm,
  });

  final String id;
  final TripDriver driver;
  final TripVehicle vehicle;
  final GeoPlace depart;
  final GeoPlace arrivee;
  final List<PickupPoint> pickupPoints;
  final DateTime departureAt;
  final int placesRestantes;
  final int prixPlace;
  final int fraisService;

  /// `publie` | `complet` | `en_cours` | `termine` | `annule`.
  final String statut;

  /// Aperçu du paiement (détail d'un trajet uniquement).
  final PaymentPreview? payment;

  /// Point de prise en charge proposé au passager par la recherche.
  final String? matchedPickupId;

  /// Distance de marche jusqu'au point proposé (renvoyée par la recherche uniquement).
  final double? walkingDistanceKm;

  PickupPoint? get matchedPickup =>
      pickupPoints.where((p) => p.id == matchedPickupId).firstOrNull ?? pickupPoints.firstOrNull;

  Trip withMatch({required String pickupId, double? walkingDistanceKm}) => Trip(
        id: id,
        driver: driver,
        vehicle: vehicle,
        depart: depart,
        arrivee: arrivee,
        pickupPoints: pickupPoints,
        departureAt: departureAt,
        placesRestantes: placesRestantes,
        prixPlace: prixPlace,
        fraisService: fraisService,
        statut: statut,
        payment: payment,
        matchedPickupId: pickupId,
        walkingDistanceKm: walkingDistanceKm ?? this.walkingDistanceKm,
      );
}
