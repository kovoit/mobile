import '../../../../core/constants/api_constants.dart';
import '../../../../core/mock/fake_driver.dart';
import '../../../../core/network/api_service.dart';
import '../dto/driver_dto.dart';

abstract interface class DriverRemoteDataSource {
  Future<DriverTripDto> publish(Map<String, dynamic> body);

  Future<List<DriverTripDto>> myTrips();

  Future<DriverTripDto> trip(String id);

  /// Demandes et réservations reçues sur un trajet (jamais de code de départ).
  Future<List<DriverRequestDto>> requests(String tripId);

  Future<DriverTripDto> cancelTrip(String id);

  Future<DriverTripDto> finishTrip(String id);

  Future<void> accept(String bookingId);

  Future<void> refuse(String bookingId);

  Future<void> submitCode(String bookingId, String code);

  Future<void> declareAbsence(String bookingId, {required double lat, required double lng});

  Future<SavingsDto> savings();
}

class ApiDriverRemoteDataSource implements DriverRemoteDataSource {
  const ApiDriverRemoteDataSource(this._api);

  final ApiService _api;

  static DriverTripDto _trip(Object? json) => DriverTripDto.fromJson(ApiService.asMap(json));

  Future<void> _action(String path, [Map<String, dynamic>? body]) => _api.post<void>(path, body: body, parse: (_) {});

  @override
  Future<DriverTripDto> publish(Map<String, dynamic> body) => _api.post(ApiEndpoints.trajets, body: body, parse: _trip);

  @override
  Future<List<DriverTripDto>> myTrips() async =>
      (await _api.getPage(ApiEndpoints.mesTrajets, pageSize: 50, item: DriverTripDto.fromJson)).results;

  @override
  Future<DriverTripDto> trip(String id) => _api.get(ApiEndpoints.trajet(id), parse: _trip);

  @override
  Future<List<DriverRequestDto>> requests(String tripId) async =>
      (await _api.getPage(ApiEndpoints.trajetReservations(tripId), pageSize: 50, item: DriverRequestDto.fromJson))
          .results;

  @override
  Future<DriverTripDto> cancelTrip(String id) => _api.post(ApiEndpoints.trajetAnnuler(id), parse: _trip);

  @override
  Future<DriverTripDto> finishTrip(String id) => _api.post(ApiEndpoints.trajetTerminer(id), parse: _trip);

  @override
  Future<void> accept(String bookingId) => _action(ApiEndpoints.reservationAccepter(bookingId));

  @override
  Future<void> refuse(String bookingId) => _action(ApiEndpoints.reservationRefuser(bookingId));

  @override
  Future<void> submitCode(String bookingId, String code) =>
      _action(ApiEndpoints.reservationCodeDepart(bookingId), {'code': code});

  @override
  Future<void> declareAbsence(String bookingId, {required double lat, required double lng}) =>
      _action(ApiEndpoints.reservationAbsent(bookingId), {'lat': lat, 'lng': lng});

  @override
  Future<SavingsDto> savings() =>
      _api.get(ApiEndpoints.moiEconomies, parse: (json) => SavingsDto.fromJson(ApiService.asMap(json)));
}

/// Fausse API conducteur (`Env.useMockApi`) : règles serveur simulées dans [FakeDriver].
class FakeDriverRemoteDataSource implements DriverRemoteDataSource {
  FakeDriverRemoteDataSource(this._fake);

  final FakeDriver _fake;

  @override
  Future<DriverTripDto> publish(Map<String, dynamic> body) async => DriverTripDto.fromJson(await _fake.publish(body));

  @override
  Future<List<DriverTripDto>> myTrips() async => [for (final j in await _fake.myTrips()) DriverTripDto.fromJson(j)];

  @override
  Future<DriverTripDto> trip(String id) async => DriverTripDto.fromJson(await _fake.trip(id));

  @override
  Future<List<DriverRequestDto>> requests(String tripId) async =>
      [for (final j in await _fake.requests(tripId)) DriverRequestDto.fromJson(j)];

  @override
  Future<DriverTripDto> cancelTrip(String id) async => DriverTripDto.fromJson(await _fake.cancelTrip(id));

  @override
  Future<DriverTripDto> finishTrip(String id) async => DriverTripDto.fromJson(await _fake.finishTrip(id));

  @override
  Future<void> accept(String bookingId) => _fake.accept(bookingId);

  @override
  Future<void> refuse(String bookingId) => _fake.refuse(bookingId);

  @override
  Future<void> submitCode(String bookingId, String code) => _fake.submitCode(bookingId, code);

  @override
  Future<void> declareAbsence(String bookingId, {required double lat, required double lng}) =>
      _fake.declareAbsence(bookingId, lat: lat, lng: lng);

  @override
  Future<SavingsDto> savings() async => SavingsDto.fromJson(await _fake.savings());
}
