import '../../domain/entities/driver_trip.dart';
import '../../domain/repositories/driver_repository.dart';
import '../datasources/driver_remote_data_source.dart';
import '../dto/driver_dto.dart';

class DriverRepositoryImpl implements DriverRepository {
  DriverRepositoryImpl(this._remote);

  final DriverRemoteDataSource _remote;

  @override
  Future<DriverTrip> publish(TripDraft draft, {required String vehiculeId}) async =>
      (await _remote.publish(publicationBody(draft, vehiculeId: vehiculeId))).toEntity();

  @override
  Future<List<DriverTrip>> myTrips() async => [for (final dto in await _remote.myTrips()) dto.toEntity()];

  @override
  Future<DriverTrip> trip(String id) async {
    final (trip, requests) = await (_remote.trip(id), _remote.requests(id)).wait;
    return trip.toEntity().withRequests([for (final r in requests) r.toEntity()]);
  }

  @override
  Future<DriverTrip> cancelTrip(String id) async {
    await _remote.cancelTrip(id);
    return trip(id);
  }

  @override
  Future<DriverTrip> finishTrip(String id) async {
    await _remote.finishTrip(id);
    return trip(id);
  }

  @override
  Future<void> accept(String bookingId) => _remote.accept(bookingId);

  @override
  Future<void> refuse(String bookingId) => _remote.refuse(bookingId);

  @override
  Future<void> submitDepartureCode(String bookingId, String code) => _remote.submitCode(bookingId, code);

  @override
  Future<void> declareAbsence(String bookingId, {required double lat, required double lng}) =>
      _remote.declareAbsence(bookingId, lat: lat, lng: lng);

  @override
  Future<DriverSavings> savings() async => (await _remote.savings()).toEntity();
}
