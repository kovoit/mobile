import '../../../trip/domain/entities/trip.dart';
import 'search_query.dart';

/// Réponse de la recherche : itinéraire du passager + trajets triés par le backend.
class SearchResult {
  const SearchResult({required this.itinerary, required this.trips});

  final Itinerary itinerary;
  final List<Trip> trips;

  /// Départ le plus tôt parmi les résultats (« Départ dès 07:30 »).
  DateTime? get earliestDeparture => trips.isEmpty
      ? null
      : trips.map((t) => t.departureAt).reduce((a, b) => a.isBefore(b) ? a : b);
}
