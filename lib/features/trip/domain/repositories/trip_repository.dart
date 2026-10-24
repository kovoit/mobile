import '../entities/trip.dart';

/// Trajet demandé, et, si connus, le point de prise en charge et l'arrivée du passager.
/// Record (égalité par valeur) : sert aussi de clé au provider du détail.
typedef TripQuery = ({String id, String? pickupId, double? arriveeLat, double? arriveeLng});

abstract interface class TripRepository {
  /// Détail d'un trajet et aperçu du paiement. `NotFoundApiException` s'il n'existe plus.
  Future<Trip> fetchTrip(TripQuery query);
}
