import '../../../trip/domain/entities/trip.dart';

/// Les 9 statuts d'une réservation (PRD §8). Les transitions sont décidées par le backend.
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

/// Actions proposées selon le statut. Le backend reste seul juge : il refuse toute action
/// devenue impossible (départ passé, note déjà donnée…) avec un message affiché tel quel.
enum BookingAction {
  annuler,
  partager,
  confirmer,
  noter,
  signaler;

  static Set<BookingAction> forStatus(BookingStatus status) => switch (status) {
        BookingStatus.demandee => {annuler},
        BookingStatus.acceptee => {annuler, partager},
        BookingStatus.enCours => {partager, signaler},
        BookingStatus.terminee => {confirmer, noter, signaler},
        BookingStatus.litige => {noter},
        BookingStatus.cloturee => {noter, signaler},
        BookingStatus.absent => {signaler},
        BookingStatus.refusee || BookingStatus.annulee => const {},
      };
}

/// Réservation vue par le passager (une place). Payée par le portefeuille : montant bloqué à la
/// demande, débité à la prise en charge (code de départ saisi par le conducteur).
class Booking {
  const Booking({
    required this.id,
    required this.trip,
    required this.status,
    required this.montantTotal,
    required this.createdAt,
    this.prix,
    this.fraisService = 0,
    this.complementPaye = 0,
    this.pickupPointId,
    this.arriveeLibelle = '',
    this.departureCode,
    this.lateCancellation = false,
  });

  final String id;
  final Trip trip;
  final BookingStatus status;

  /// Prix + frais de service (F CFA), fixés par le backend.
  final int montantTotal;
  final int? prix;
  final int fraisService;

  /// Part payée par Mobile Money au moment de la demande (0 avec PayGate : recharge préalable).
  final int complementPaye;
  final DateTime createdAt;
  final String? pickupPointId;

  /// Destination du passager.
  final String arriveeLibelle;

  /// Code de départ à 4 chiffres : affiché au passager uniquement, jamais journalisé.
  final String? departureCode;
  final bool lateCancellation;

  Set<BookingAction> get actions => BookingAction.forStatus(status);

  bool can(BookingAction action) => actions.contains(action);

  PickupPoint? get pickupPoint =>
      trip.pickupPoints.where((p) => p.id == pickupPointId).firstOrNull ?? trip.matchedPickup;
}

/// Lien public temporaire « Partager mon trajet ».
class ShareLink {
  const ShareLink({required this.url});

  final String url;
}
