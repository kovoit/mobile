import '../../../../core/constants/api_constants.dart';
import '../../../../core/mock/fake_backend.dart';
import '../../../../core/mock/fake_trips.dart';
import '../../../../core/network/api_service.dart';
import '../../../trip/data/dto/trip_dto.dart';
import '../dto/search_response_dto.dart';

/// Paramètres de `GET /trajets/recherche/` (déjà au format API).
typedef SearchParams = ({
  double departLat,
  double departLng,
  double arriveeLat,
  double arriveeLng,
  DateTime dateHeure,
});

abstract interface class SearchRemoteDataSource {
  /// `GET /lieux/?q=` : lieux connus de Lomé (2 caractères minimum pour filtrer).
  Future<List<GeoPlaceDto>> searchPlaces(String query);

  Future<List<SearchMatchDto>> search(SearchParams params);
}

class ApiSearchRemoteDataSource implements SearchRemoteDataSource {
  const ApiSearchRemoteDataSource(this._api);

  final ApiService _api;

  @override
  Future<List<GeoPlaceDto>> searchPlaces(String query) => _api.get(
        ApiEndpoints.lieux,
        query: {if (query.isNotEmpty) 'q': query},
        parse: (json) => [for (final item in ApiService.asList(json)) GeoPlaceDto.fromJson(ApiService.asMap(item))],
      );

  @override
  Future<List<SearchMatchDto>> search(SearchParams p) => _api.get(
        ApiEndpoints.trajetsRecherche,
        query: {
          'depart_lat': p.departLat,
          'depart_lng': p.departLng,
          'arrivee_lat': p.arriveeLat,
          'arrivee_lng': p.arriveeLng,
          'date_heure': p.dateHeure.toUtc().toIso8601String(),
        },
        parse: (json) => [for (final item in ApiService.asList(json)) SearchMatchDto.fromJson(ApiService.asMap(item))],
      );
}

/// Fausse API de recherche (`Env.useMockApi`) : règles serveur simulées dans [FakeTrips].
class FakeSearchRemoteDataSource implements SearchRemoteDataSource {
  FakeSearchRemoteDataSource(this._backend);

  final FakeBackend _backend;

  @override
  Future<List<GeoPlaceDto>> searchPlaces(String query) async {
    await _backend.wait();
    return [for (final json in FakeTrips.searchPlaces(query)) GeoPlaceDto.fromJson(json)];
  }

  @override
  Future<List<SearchMatchDto>> search(SearchParams p) async {
    await _backend.wait();
    await _backend.currentUserId();
    final results = FakeTrips.search(
      departLat: p.departLat,
      departLng: p.departLng,
      arriveeLat: p.arriveeLat,
      arriveeLng: p.arriveeLng,
      dateHeure: p.dateHeure,
    );
    return [for (final json in results) SearchMatchDto.fromJson(json)];
  }
}
