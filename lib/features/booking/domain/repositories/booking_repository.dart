import '../entities/booking.dart';

abstract interface class BookingRepository {
  /// Demande de place (CA2). Le backend vérifie KYC, places et doublons.
  Future<Booking> request({
    required int tripId,
    required int places,
    required int pickupPointId,
    required PaymentMethod method,
  });

  /// Réservations du passager, récentes d'abord.
  Future<List<Booking>> fetchMine();

  Future<Booking> fetch(int id);

  /// Annulation (CA5) : le backend indique si elle est tardive.
  Future<Booking> cancel(int id);

  /// Lance le paiement Flooz / Mixx depuis le numéro [telephone] (E.164).
  Future<Booking> pay(int id, {required String telephone});

  Future<ShareLink> shareLink(int id);
}
