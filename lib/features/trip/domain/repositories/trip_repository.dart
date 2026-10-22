import '../entities/trip.dart';

abstract interface class TripRepository {
  /// Détail d'un trajet et aperçu du paiement. `NotFoundApiException` s'il n'existe plus.
  Future<Trip> fetchTrip(String id);
}
