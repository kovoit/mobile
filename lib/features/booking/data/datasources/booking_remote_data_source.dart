import '../../../../core/constants/api_constants.dart';
import '../../../../core/mock/fake_bookings.dart';
import '../../../../core/network/api_service.dart';
import '../dto/booking_dto.dart';

/// Destination du passager envoyée avec la demande de place.
typedef Destination = ({String libelle, double lat, double lng});

abstract interface class BookingRemoteDataSource {
  Future<BookingDto> request({required String tripId, required String pickupPointId, required Destination arrivee});

  Future<List<BookingDto>> fetchMine();

  Future<BookingDto> fetch(String id);

  Future<BookingDto> cancel(String id);

  /// `{jeton, chemin}` : `chemin` est relatif au serveur de l'API.
  Future<Map<String, dynamic>> share(String id);

  Future<BookingDto> confirm(String id);
}

class ApiBookingRemoteDataSource implements BookingRemoteDataSource {
  const ApiBookingRemoteDataSource(this._api);

  final ApiService _api;

  static BookingDto _booking(Object? json) => BookingDto.fromJson(ApiService.asMap(json));

  @override
  Future<BookingDto> request({required String tripId, required String pickupPointId, required Destination arrivee}) =>
      _api.post(
        ApiEndpoints.reservations,
        body: {
          'trajet_id': tripId,
          'point_id': pickupPointId,
          'arrivee_lat': arrivee.lat,
          'arrivee_lng': arrivee.lng,
          'arrivee_libelle': arrivee.libelle,
        },
        parse: _booking,
      );

  /// Réservations du passager, plus récentes d'abord (50 dernières).
  @override
  Future<List<BookingDto>> fetchMine() async =>
      (await _api.getPage(ApiEndpoints.reservations, pageSize: 50, item: BookingDto.fromJson)).results;

  @override
  Future<BookingDto> fetch(String id) => _api.get(ApiEndpoints.reservation(id), parse: _booking);

  @override
  Future<BookingDto> cancel(String id) => _api.post(ApiEndpoints.reservationAnnuler(id), parse: _booking);

  @override
  Future<Map<String, dynamic>> share(String id) =>
      _api.post(ApiEndpoints.reservationPartage(id), parse: ApiService.asMap);

  @override
  Future<BookingDto> confirm(String id) =>
      _api.post(ApiEndpoints.reservationConfirmerArrivee(id), parse: _booking);
}

/// Fausse API (`Env.useMockApi`) : règles serveur simulées dans [FakeBookings].
class FakeBookingRemoteDataSource implements BookingRemoteDataSource {
  FakeBookingRemoteDataSource(this._fake);

  final FakeBookings _fake;

  @override
  Future<BookingDto> request({required String tripId, required String pickupPointId, required Destination arrivee}) async =>
      BookingDto.fromJson(
        await _fake.request(
          tripId: tripId,
          pickupPointId: pickupPointId,
          arriveeLat: arrivee.lat,
          arriveeLng: arrivee.lng,
          arriveeLibelle: arrivee.libelle,
        ),
      );

  @override
  Future<List<BookingDto>> fetchMine() async => [for (final json in await _fake.listMine()) BookingDto.fromJson(json)];

  @override
  Future<BookingDto> fetch(String id) async => BookingDto.fromJson(await _fake.get(id));

  @override
  Future<BookingDto> cancel(String id) async => BookingDto.fromJson(await _fake.cancel(id));

  @override
  Future<Map<String, dynamic>> share(String id) => _fake.share(id);

  @override
  Future<BookingDto> confirm(String id) async => BookingDto.fromJson(await _fake.confirm(id));
}
