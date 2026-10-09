import 'package:dio/dio.dart';

import '../../../../core/mock/fake_backend.dart';
import '../../../../core/mock/fake_trips.dart';
import '../../../../core/network/api_exception.dart';
import '../../../trip/data/dto/trip_dto.dart';
import '../dto/search_response_dto.dart';

/// Paramètres de `GET /trajets/recherche/` (déjà au format API).
typedef SearchParams = ({
  double departLat,
  double departLng,
  double arriveeLat,
  double arriveeLng,
  DateTime dateHeure,
  int places,
  String typeVehicule,
});

abstract interface class SearchRemoteDataSource {
  Future<List<GeoPlaceDto>> searchPlaces(String query);

  Future<SearchResponseDto> search(SearchParams params);
}

class DioSearchRemoteDataSource implements SearchRemoteDataSource {
  DioSearchRemoteDataSource(this._dio);

  final Dio _dio;

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<List<GeoPlaceDto>> searchPlaces(String query) => _call(() async {
        final res = await _dio.get<List<dynamic>>('/lieux/', queryParameters: {if (query.isNotEmpty) 'q': query});
        return [for (final item in res.data!) GeoPlaceDto.fromJson(item as Map<String, dynamic>)];
      });

  @override
  Future<SearchResponseDto> search(SearchParams p) => _call(() async {
        final res = await _dio.get<Map<String, dynamic>>(
          '/trajets/recherche/',
          queryParameters: {
            'depart_lat': p.departLat,
            'depart_lng': p.departLng,
            'arrivee_lat': p.arriveeLat,
            'arrivee_lng': p.arriveeLng,
            'date_heure': p.dateHeure.toUtc().toIso8601String(),
            'places': p.places,
            'type_vehicule': p.typeVehicule,
          },
        );
        return SearchResponseDto.fromJson(res.data!);
      });
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
  Future<SearchResponseDto> search(SearchParams p) async {
    await _backend.wait();
    await _backend.currentUserId();
    final json = FakeTrips.search(
      departLat: p.departLat,
      departLng: p.departLng,
      arriveeLat: p.arriveeLat,
      arriveeLng: p.arriveeLng,
      dateHeure: p.dateHeure,
      places: p.places,
      typeVehicule: p.typeVehicule,
    );
    return SearchResponseDto.fromJson(json);
  }
}
