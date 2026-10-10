import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_remote_data_source.dart';

class BookingRepositoryImpl implements BookingRepository {
  BookingRepositoryImpl(this._remote);

  final BookingRemoteDataSource _remote;

  @override
  Future<Booking> request({
    required int tripId,
    required int places,
    required int pickupPointId,
    required PaymentMethod method,
  }) async =>
      (await _remote.request(tripId: tripId, places: places, pickupPointId: pickupPointId, method: method.apiValue))
          .toEntity();

  @override
  Future<List<Booking>> fetchMine() async => [for (final dto in await _remote.fetchMine()) dto.toEntity()];

  @override
  Future<Booking> fetch(int id) async => (await _remote.fetch(id)).toEntity();

  @override
  Future<Booking> cancel(int id) async => (await _remote.cancel(id)).toEntity();

  @override
  Future<Booking> pay(int id, {required String telephone}) async =>
      (await _remote.pay(id, telephone: telephone)).toEntity();

  @override
  Future<ShareLink> shareLink(int id) async {
    final json = await _remote.share(id);
    return ShareLink(
      url: json['url'] as String,
      expiresAt: json['expire_le'] == null ? null : DateTime.parse(json['expire_le'] as String),
    );
  }
}
