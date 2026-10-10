import 'package:dio/dio.dart';

import '../../../../core/mock/fake_driver.dart';
import '../../../../core/network/api_exception.dart';
import '../dto/driver_dto.dart';

abstract interface class DriverRemoteDataSource {
  Future<PriceEstimateDto> estimate(Map<String, dynamic> body);

  Future<DriverTripDto> publish(Map<String, dynamic> body);

  Future<List<DriverTripDto>> myTrips();

  Future<DriverTripDto> trip(int id);

  Future<DriverTripDto> cancelTrip(int id);

  Future<DriverTripDto> finishTrip(int id);

  Future<void> accept(int bookingId);

  Future<void> refuse(int bookingId);

  Future<void> submitCode(int bookingId, String code);

  Future<void> declareAbsence(int bookingId, {required double lat, required double lng});

  Future<SavingsDto> savings();
}

class DioDriverRemoteDataSource implements DriverRemoteDataSource {
  DioDriverRemoteDataSource(this._dio);

  final Dio _dio;

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<DriverTripDto> _tripPost(String path) => _call(() async {
        final res = await _dio.post<Map<String, dynamic>>(path);
        return DriverTripDto.fromJson(res.data!);
      });

  Future<void> _post(String path, [Map<String, dynamic>? data]) => _call(() => _dio.post<dynamic>(path, data: data));

  @override
  Future<PriceEstimateDto> estimate(Map<String, dynamic> body) => _call(() async {
        final res = await _dio.post<Map<String, dynamic>>('/trajets/prix/', data: body);
        return PriceEstimateDto.fromJson(res.data!);
      });

  @override
  Future<DriverTripDto> publish(Map<String, dynamic> body) => _call(() async {
        final res = await _dio.post<Map<String, dynamic>>('/trajets/', data: body);
        return DriverTripDto.fromJson(res.data!);
      });

  @override
  Future<List<DriverTripDto>> myTrips() => _call(() async {
        final res = await _dio.get<List<dynamic>>('/trajets/mes-trajets/');
        return [for (final item in res.data!) DriverTripDto.fromJson(item as Map<String, dynamic>)];
      });

  @override
  Future<DriverTripDto> trip(int id) => _call(() async {
        final res = await _dio.get<Map<String, dynamic>>('/trajets/$id/conducteur/');
        return DriverTripDto.fromJson(res.data!);
      });

  @override
  Future<DriverTripDto> cancelTrip(int id) => _tripPost('/trajets/$id/annuler/');

  @override
  Future<DriverTripDto> finishTrip(int id) => _tripPost('/trajets/$id/terminer/');

  @override
  Future<void> accept(int bookingId) => _post('/reservations/$bookingId/accepter/');

  @override
  Future<void> refuse(int bookingId) => _post('/reservations/$bookingId/refuser/');

  @override
  Future<void> submitCode(int bookingId, String code) => _post('/reservations/$bookingId/code/', {'code': code});

  @override
  Future<void> declareAbsence(int bookingId, {required double lat, required double lng}) =>
      _post('/reservations/$bookingId/absence/', {'lat': lat, 'lng': lng});

  @override
  Future<SavingsDto> savings() => _call(() async {
        final res = await _dio.get<Map<String, dynamic>>('/conducteur/economies/');
        return SavingsDto.fromJson(res.data!);
      });
}

/// Fausse API conducteur (`Env.useMockApi`) : règles serveur simulées dans [FakeDriver].
class FakeDriverRemoteDataSource implements DriverRemoteDataSource {
  FakeDriverRemoteDataSource(this._fake);

  final FakeDriver _fake;

  @override
  Future<PriceEstimateDto> estimate(Map<String, dynamic> body) async => PriceEstimateDto.fromJson(
        await _fake.estimate(
          depart: body['depart'] as Map<String, dynamic>,
          arrivee: body['arrivee'] as Map<String, dynamic>,
        ),
      );

  @override
  Future<DriverTripDto> publish(Map<String, dynamic> body) async => DriverTripDto.fromJson(await _fake.publish(body));

  @override
  Future<List<DriverTripDto>> myTrips() async => [for (final j in await _fake.myTrips()) DriverTripDto.fromJson(j)];

  @override
  Future<DriverTripDto> trip(int id) async => DriverTripDto.fromJson(await _fake.trip(id));

  @override
  Future<DriverTripDto> cancelTrip(int id) async => DriverTripDto.fromJson(await _fake.cancelTrip(id));

  @override
  Future<DriverTripDto> finishTrip(int id) async => DriverTripDto.fromJson(await _fake.finishTrip(id));

  @override
  Future<void> accept(int bookingId) => _fake.accept(bookingId);

  @override
  Future<void> refuse(int bookingId) => _fake.refuse(bookingId);

  @override
  Future<void> submitCode(int bookingId, String code) => _fake.submitCode(bookingId, code);

  @override
  Future<void> declareAbsence(int bookingId, {required double lat, required double lng}) =>
      _fake.declareAbsence(bookingId, lat: lat, lng: lng);

  @override
  Future<SavingsDto> savings() async => SavingsDto.fromJson(await _fake.savings());
}
