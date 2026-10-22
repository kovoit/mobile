import '../entities/booking.dart';

abstract interface class BookingRepository {
  /// Demande d'une place. Le backend vérifie KYC, places, doublons et solde du portefeuille
  /// (`SOLDE_INSUFFISANT` avec le complément à recharger).
  Future<Booking> request({
    required String tripId,
    required String pickupPointId,
    required ({String libelle, double lat, double lng}) arrivee,
  });

  /// Réservations du passager, récentes d'abord.
  Future<List<Booking>> fetchMine();

  Future<Booking> fetch(String id);

  /// Annulation : le backend indique si elle est tardive.
  Future<Booking> cancel(String id);

  Future<ShareLink> shareLink(String id);

  /// Le passager confirme son arrivée : la réservation passe `cloturee`.
  Future<Booking> confirmArrival(String id);
}
