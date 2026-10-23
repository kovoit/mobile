import '../../../../core/config/env.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_remote_data_source.dart';

class BookingRepositoryImpl implements BookingRepository {
  BookingRepositoryImpl(this._remote);

  final BookingRemoteDataSource _remote;

  @override
  Future<Booking> request({
    required String tripId,
    required String pickupPointId,
    required ({String libelle, double lat, double lng}) arrivee,
  }) async =>
      (await _remote.request(tripId: tripId, pickupPointId: pickupPointId, arrivee: arrivee)).toEntity();

  @override
  Future<List<Booking>> fetchMine() async => [for (final dto in await _remote.fetchMine()) dto.toEntity()];

  @override
  Future<Booking> fetch(String id) async => (await _remote.fetch(id)).toEntity();

  @override
  Future<Booking> cancel(String id) async => (await _remote.cancel(id)).toEntity();

  @override
  Future<Booking> confirmArrival(String id) async => (await _remote.confirm(id)).toEntity();

  /// Le backend renvoie un chemin relatif à son serveur (`/suivi/<jeton>/`, page lisible par le proche).
  @override
  Future<ShareLink> shareLink(String id) async {
    final json = await _remote.share(id);
    return ShareLink(url: Uri.parse(Env.apiBaseUrl).resolve(json['chemin'] as String).toString());
  }
}
