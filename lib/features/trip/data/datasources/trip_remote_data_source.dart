import 'package:dio/dio.dart';

import '../../../../core/mock/fake_backend.dart';
import '../../../../core/mock/fake_trips.dart';
import '../../../../core/network/api_exception.dart';
import '../dto/trip_dto.dart';

abstract interface class TripRemoteDataSource {
  Future<TripDto> fetchTrip(int id, {int places = 1});
}

class DioTripRemoteDataSource implements TripRemoteDataSource {
  DioTripRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<TripDto> fetchTrip(int id, {int places = 1}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/trajets/$id/', queryParameters: {'places': places});
      return TripDto.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

/// Fausse API trajets (`Env.useMockApi`).
class FakeTripRemoteDataSource implements TripRemoteDataSource {
  FakeTripRemoteDataSource(this._backend);

  final FakeBackend _backend;

  @override
  Future<TripDto> fetchTrip(int id, {int places = 1}) async {
    await _backend.wait();
    await _backend.currentUserId();
    final json = FakeTrips.tripById(id, places: places);
    if (json == null) throw const NotFoundApiException('Ce trajet n’est plus disponible.');
    return TripDto.fromJson(json);
  }
}
