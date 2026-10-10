import '../../../trip/domain/entities/trip.dart';

/// Les 9 statuts d'une réservation (PRD §7). Les transitions sont décidées par le backend.
enum BookingStatus {
  demandee('demandee'),
  acceptee('acceptee'),
  refusee('refusee'),
  annulee('annulee'),
  absent('absent'),
  enCours('en_cours'),
  terminee('terminee'),
  litige('litige'),
  cloturee('cloturee');

  const BookingStatus(this.apiValue);

  final String apiValue;

  static BookingStatus fromApi(String? value) =>
      values.firstWhere((s) => s.apiValue == value, orElse: () => BookingStatus.demandee);

  /// Réservation en cours de vie (affichée dans « À venir »).
  bool get isUpcoming => this == demandee || this == acceptee || this == enCours;
}

/// Moyen de paiement choisi par le passager (décision D5/D7 du 09/10/2026).
enum PaymentMethod {
  especes('especes'),
  flooz('flooz'),
  mixx('mixx');

  const PaymentMethod(this.apiValue);

  final String apiValue;

  bool get isMobileMoney => this != especes;

  static PaymentMethod fromApi(String? value) =>
      values.firstWhere((m) => m.apiValue == value, orElse: () => PaymentMethod.especes);
}

enum PaymentStatus {
  nonRequis('non_requis'),
  aPayer('a_payer'),
  enAttente('en_attente'),
  reussi('reussi'),
  echoue('echoue'),
  rembourse('rembourse');

  const PaymentStatus(this.apiValue);

  final String apiValue;

  static PaymentStatus fromApi(String? value) =>
      values.firstWhere((s) => s.apiValue == value, orElse: () => PaymentStatus.nonRequis);
}

class Payment {
  const Payment({
    required this.method,
    required this.status,
    required this.montant,
    this.telephone,
    this.reference,
    this.message,
  });

  final PaymentMethod method;
  final PaymentStatus status;
  final int montant;
  final String? telephone;
  final String? reference;

  /// Consigne de l'opérateur (« Validez le paiement sur votre téléphone… »).
  final String? message;
}

/// Actions autorisées maintenant, renvoyées par l'API (claude.md §4).
enum BookingAction {
  annuler('annuler'),
  payer('payer'),
  partager('partager'),
  appeler('appeler');

  const BookingAction(this.apiValue);

  final String apiValue;

  static BookingAction? fromApi(String value) => values.where((a) => a.apiValue == value).firstOrNull;
}

/// Réservation vue par le passager.
class Booking {
  const Booking({
    required this.id,
    required this.trip,
    required this.places,
    required this.status,
    required this.prixTotal,
    required this.payment,
    required this.createdAt,
    this.fraisService = 0,
    this.pickupPointId,
    this.departureCode,
    this.freeCancellationUntil,
    this.lateCancellation = false,
    this.driverPhone,
    this.driverPosition,
    this.driverEtaMin,
    this.actions = const {},
  });

  final int id;
  final Trip trip;
  final int places;
  final BookingStatus status;
  final int prixTotal;
  final int fraisService;
  final Payment payment;
  final DateTime createdAt;
  final int? pickupPointId;

  /// Code de départ à 4 chiffres : affiché au passager uniquement, jamais journalisé.
  final String? departureCode;
  final DateTime? freeCancellationUntil;
  final bool lateCancellation;
  final String? driverPhone;
  final (double lat, double lng)? driverPosition;
  final int? driverEtaMin;
  final Set<BookingAction> actions;

  bool can(BookingAction action) => actions.contains(action);

  PickupPoint? get pickupPoint =>
      trip.pickupPoints.where((p) => p.id == pickupPointId).firstOrNull ?? trip.matchedPickup;
}

/// Lien public temporaire « Partager mon trajet ».
class ShareLink {
  const ShareLink({required this.url, this.expiresAt});

  final String url;
  final DateTime? expiresAt;
}
