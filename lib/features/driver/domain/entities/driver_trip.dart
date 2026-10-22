import '../../../booking/domain/entities/booking.dart';
import '../../../trip/domain/entities/geo_place.dart';
import '../../../trip/domain/entities/trip.dart';

/// Statut d'un trajet publié (PRD §7).
enum TripStatus {
  publie('publie'),
  complet('complet'),
  enCours('en_cours'),
  termine('termine'),
  annule('annule');

  const TripStatus(this.apiValue);

  final String apiValue;

  static TripStatus fromApi(String? value) =>
      values.firstWhere((s) => s.apiValue == value, orElse: () => TripStatus.publie);

  bool get isUpcoming => this == publie || this == complet || this == enCours;
}

/// Actions proposées sur un trajet publié, selon son statut (le backend refuse les autres).
enum DriverTripAction {
  annuler,
  terminer;

  static Set<DriverTripAction> forStatus(TripStatus status) => switch (status) {
        TripStatus.publie || TripStatus.complet => {annuler, terminer},
        TripStatus.enCours => {terminer},
        TripStatus.termine || TripStatus.annule => const {},
      };
}

/// Actions proposées sur une demande reçue, selon son statut (le backend refuse les autres).
enum DriverRequestAction {
  accepter,
  refuser,
  saisirCode,
  declarerAbsence,
  noter,
  signaler;

  /// [placesLeft] : places restantes du trajet (renvoyées par le backend).
  static Set<DriverRequestAction> forStatus(BookingStatus status, {required bool tripOpen, int placesLeft = 1}) =>
      switch (status) {
        BookingStatus.demandee when tripOpen => {if (placesLeft > 0) accepter, refuser},
        BookingStatus.acceptee when tripOpen => {saisirCode, declarerAbsence},
        BookingStatus.enCours => {signaler},
        BookingStatus.terminee || BookingStatus.cloturee || BookingStatus.absent => {noter, signaler},
        BookingStatus.litige => {noter},
        _ => const {},
      };
}

class PassengerSummary {
  const PassengerSummary({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.verifie,
    this.photoUrl,
    this.note,
  });

  final String id;
  final String prenom;
  final String nom;
  final bool verifie;
  final String? photoUrl;
  final double? note;

  String get nomComplet => '$prenom $nom'.trim();
}

/// Réservation vue par le conducteur (une place). **Jamais de code de départ** (claude.md §1.5).
class DriverRequest {
  const DriverRequest({
    required this.id,
    required this.passenger,
    required this.status,
    required this.montant,
    this.pickupPointId,
    this.essaisCode = 0,
  });

  final String id;
  final PassengerSummary passenger;
  final BookingStatus status;

  /// Ce que le conducteur reçoit pour cette place (prix, hors frais de service Kovoit).
  final int montant;
  final String? pickupPointId;
  final int essaisCode;
}

/// Trajet publié par le conducteur, avec ses demandes.
class DriverTrip {
  const DriverTrip({
    required this.id,
    required this.depart,
    required this.arrivee,
    required this.pickupPoints,
    required this.departureAt,
    required this.placesTotal,
    required this.placesRestantes,
    required this.prixPlace,
    required this.status,
    this.nbDemandes = 0,
    this.requests = const [],
  });

  final String id;
  final GeoPlace depart;
  final GeoPlace arrivee;
  final List<PickupPoint> pickupPoints;
  final DateTime departureAt;
  final int placesTotal;
  final int placesRestantes;
  final int prixPlace;
  final TripStatus status;

  /// Demandes en attente de réponse (calculé par le backend).
  final int nbDemandes;
  final List<DriverRequest> requests;

  Set<DriverTripAction> get actions => DriverTripAction.forStatus(status);

  bool can(DriverTripAction action) => actions.contains(action);

  Set<DriverRequestAction> actionsFor(DriverRequest request) =>
      DriverRequestAction.forStatus(request.status, tripOpen: status.isUpcoming, placesLeft: placesRestantes);

  int get pendingRequests =>
      requests.isEmpty ? nbDemandes : requests.where((r) => r.status == BookingStatus.demandee).length;

  PickupPoint? pickupFor(DriverRequest request) => pickupPoints.where((p) => p.id == request.pickupPointId).firstOrNull;

  DriverTrip withRequests(List<DriverRequest> requests) => DriverTrip(
        id: id,
        depart: depart,
        arrivee: arrivee,
        pickupPoints: pickupPoints,
        departureAt: departureAt,
        placesTotal: placesTotal,
        placesRestantes: placesRestantes,
        prixPlace: prixPlace,
        status: status,
        nbDemandes: nbDemandes,
        requests: requests,
      );
}

/// Ce qu'un trajet a rapporté au conducteur (somme payée par ses passagers).
class TripSaving {
  const TripSaving({
    required this.tripId,
    required this.departureAt,
    required this.depart,
    required this.arrivee,
    required this.montant,
  });

  final String tripId;
  final DateTime departureAt;
  final String depart;
  final String arrivee;
  final int montant;
}

/// Économies du conducteur (PRD : par trajet et cumul du mois), calculées par le backend.
class DriverSavings {
  const DriverSavings({required this.moisEnCours, required this.total, this.parTrajet = const []});

  final int moisEnCours;
  final int total;
  final List<TripSaving> parTrajet;
}

/// Trajet à publier (saisie du conducteur, avant validation serveur).
class TripDraft {
  const TripDraft({
    required this.depart,
    required this.arrivee,
    required this.pickupPoints,
    required this.departureAt,
    required this.places,
  });

  final GeoPlace depart;
  final GeoPlace arrivee;
  final List<GeoPlace> pickupPoints;
  final DateTime departureAt;
  final int places;
}
