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

/// Actions autorisées sur un trajet publié, renvoyées par l'API.
enum DriverTripAction {
  annuler('annuler'),
  terminer('terminer');

  const DriverTripAction(this.apiValue);

  final String apiValue;

  static DriverTripAction? fromApi(String value) => values.where((a) => a.apiValue == value).firstOrNull;
}

/// Actions autorisées sur une demande reçue, renvoyées par l'API.
enum DriverRequestAction {
  accepter('accepter'),
  refuser('refuser'),
  saisirCode('saisir_code'),
  declarerAbsence('declarer_absence');

  const DriverRequestAction(this.apiValue);

  final String apiValue;

  static DriverRequestAction? fromApi(String value) => values.where((a) => a.apiValue == value).firstOrNull;
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

  final int id;
  final String prenom;
  final String nom;
  final bool verifie;
  final String? photoUrl;
  final double? note;

  String get nomComplet => '$prenom $nom'.trim();
}

/// Réservation vue par le conducteur. **Ne contient jamais le code de départ** (claude.md §1.5).
class DriverRequest {
  const DriverRequest({
    required this.id,
    required this.passenger,
    required this.places,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.montant,
    this.pickupPointId,
    this.actions = const {},
  });

  final int id;
  final PassengerSummary passenger;
  final int places;
  final BookingStatus status;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final int montant;
  final int? pickupPointId;
  final Set<DriverRequestAction> actions;

  bool can(DriverRequestAction action) => actions.contains(action);
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
    this.economie = 0,
    this.requests = const [],
    this.actions = const {},
  });

  final int id;
  final GeoPlace depart;
  final GeoPlace arrivee;
  final List<PickupPoint> pickupPoints;
  final DateTime departureAt;
  final int placesTotal;
  final int placesRestantes;
  final int prixPlace;
  final TripStatus status;

  /// Somme payée par les passagers de ce trajet, calculée par le backend.
  final int economie;
  final List<DriverRequest> requests;
  final Set<DriverTripAction> actions;

  bool can(DriverTripAction action) => actions.contains(action);

  int get pendingRequests => requests.where((r) => r.status == BookingStatus.demandee).length;

  PickupPoint? pickupFor(DriverRequest request) => pickupPoints.where((p) => p.id == request.pickupPointId).firstOrNull;
}

/// Prix recommandé par le backend avant publication.
class PriceEstimate {
  const PriceEstimate({required this.prixPlace, required this.distanceKm, required this.durationMin});

  final int prixPlace;
  final double distanceKm;
  final int durationMin;
}

/// Économies du conducteur sur un mois (spéc. « Économies affichées au conducteur »).
class DriverSavings {
  const DriverSavings({required this.month, required this.total, required this.places});

  final DateTime month;
  final int total;
  final int places;
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
