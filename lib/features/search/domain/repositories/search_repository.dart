import '../../../trip/domain/entities/geo_place.dart';
import '../entities/search_query.dart';
import '../entities/search_result.dart';

abstract interface class SearchRepository {
  /// Lieux connus de Lomé correspondant à [query] (carrefours, quartiers, repères).
  Future<List<GeoPlace>> searchPlaces(String query);

  /// Trajets correspondants : correspondance et tri faits par le backend.
  Future<SearchResult> search(SearchQuery query);
}

/// Recherches récentes, stockées sur l'appareil (non sensibles).
class RecentSearch {
  const RecentSearch({required this.depart, required this.arrivee, required this.vehicleTypeApi});

  final GeoPlace depart;
  final GeoPlace arrivee;
  final String vehicleTypeApi;
}

abstract interface class RecentSearchRepository {
  Future<List<RecentSearch>> load();

  /// Ajoute en tête (sans doublon), garde les plus récentes.
  Future<List<RecentSearch>> remember(RecentSearch search);
}
