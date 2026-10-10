import 'package:dio/dio.dart';

import '../../../../core/mock/fake_bookings.dart';
import '../../../../core/network/api_exception.dart';
import '../dto/booking_dto.dart';

abstract interface class BookingRemoteDataSource {
  Future<BookingDto> request({
    required int tripId,
    required int places,
    required int pickupPointId,
    required String method,
  });

  Future<List<BookingDto>> fetchMine();

  Future<BookingDto> fetch(int id);

  Future<BookingDto> cancel(int id);

  Future<BookingDto> pay(int id, {required String telephone});

  /// `{url, expire_le}`
  Future<Map<String, dynamic>> share(int id);
}

class DioBookingRemoteDataSource implements BookingRemoteDataSource {
  DioBookingRemoteDataSource(this._dio);

  final Dio _dio;

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<BookingDto> _post(String path, [Map<String, dynamic>? data]) => _call(() async {
        final res = await _dio.post<Map<String, dynamic>>(path, data: data);
        return BookingDto.fromJson(res.data!);
      });

  @override
  Future<BookingDto> request({
    required int tripId,
    required int places,
    required int pickupPointId,
    required String method,
  }) =>
      _post('/reservations/', {
        'trajet_id': tripId,
        'nb_places': places,
        'point_prise_en_charge_id': pickupPointId,
        'methode_paiement': method,
      });

  @override
  Future<List<BookingDto>> fetchMine() => _call(() async {
        final res = await _dio.get<List<dynamic>>('/reservations/', queryParameters: {'role': 'passager'});
        return [for (final item in res.data!) BookingDto.fromJson(item as Map<String, dynamic>)];
      });

  @override
  Future<BookingDto> fetch(int id) => _call(() async {
        final res = await _dio.get<Map<String, dynamic>>('/reservations/$id/');
        return BookingDto.fromJson(res.data!);
      });

  @override
  Future<BookingDto> cancel(int id) => _post('/reservations/$id/annuler/');

  @override
  Future<BookingDto> pay(int id, {required String telephone}) =>
      _post('/reservations/$id/paiement/', {'telephone': telephone});

  @override
  Future<Map<String, dynamic>> share(int id) => _call(() async {
        final res = await _dio.post<Map<String, dynamic>>('/reservations/$id/partage/');
        return res.data!;
      });
}

/// Fausse API (`Env.useMockApi`) : règles serveur simulées dans [FakeBookings].
class FakeBookingRemoteDataSource implements BookingRemoteDataSource {
  FakeBookingRemoteDataSource(this._fake);

  final FakeBookings _fake;

  @override
  Future<BookingDto> request({
    required int tripId,
    required int places,
    required int pickupPointId,
    required String method,
  }) async =>
      BookingDto.fromJson(
        await _fake.request(tripId: tripId, places: places, pickupPointId: pickupPointId, method: method),
      );

  @override
  Future<List<BookingDto>> fetchMine() async => [for (final json in await _fake.listMine()) BookingDto.fromJson(json)];

  @override
  Future<BookingDto> fetch(int id) async => BookingDto.fromJson(await _fake.get(id));

  @override
  Future<BookingDto> cancel(int id) async => BookingDto.fromJson(await _fake.cancel(id));

  @override
  Future<BookingDto> pay(int id, {required String telephone}) async =>
      BookingDto.fromJson(await _fake.pay(id, telephone: telephone));

  @override
  Future<Map<String, dynamic>> share(int id) => _fake.share(id);
}
