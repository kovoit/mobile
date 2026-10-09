import '../entities/trip.dart';

abstract interface class TripRepository {
  /// Détail d'un trajet (prix calculé pour [places]). `NotFoundApiException` s'il n'est plus disponible.
  Future<Trip> fetchTrip(int id, {int places = 1});
}
