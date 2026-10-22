import '../../../trip/domain/entities/trip.dart';

/// Trajets correspondants, triés par le backend (heure de départ, puis distance de marche).
/// Chaque trajet porte le point de prise en charge proposé et la distance de marche.
class SearchResult {
  const SearchResult({required this.trips});

  final List<Trip> trips;

  /// Départ le plus tôt parmi les résultats (« Départ dès 07:30 »).
  DateTime? get earliestDeparture => trips.isEmpty
      ? null
      : trips.map((t) => t.departureAt).reduce((a, b) => a.isBefore(b) ? a : b);
}
