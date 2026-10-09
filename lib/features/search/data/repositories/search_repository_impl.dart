import '../../../trip/domain/entities/geo_place.dart';
import '../../domain/entities/search_query.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_remote_data_source.dart';

class SearchRepositoryImpl implements SearchRepository {
  SearchRepositoryImpl(this._remote);

  final SearchRemoteDataSource _remote;

  @override
  Future<List<GeoPlace>> searchPlaces(String query) async =>
      [for (final dto in await _remote.searchPlaces(query.trim())) dto.toEntity()];

  @override
  Future<SearchResult> search(SearchQuery query) async {
    final response = await _remote.search((
      departLat: query.depart.lat,
      departLng: query.depart.lng,
      arriveeLat: query.arrivee.lat,
      arriveeLng: query.arrivee.lng,
      dateHeure: query.dateTime,
      places: query.places,
      typeVehicule: query.vehicleType.apiValue,
    ));
    return response.toEntity();
  }
}
