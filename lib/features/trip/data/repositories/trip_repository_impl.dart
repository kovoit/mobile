import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';
import '../datasources/trip_remote_data_source.dart';

class TripRepositoryImpl implements TripRepository {
  TripRepositoryImpl(this._remote);

  final TripRemoteDataSource _remote;

  @override
  Future<Trip> fetchTrip(int id, {int places = 1}) async => (await _remote.fetchTrip(id, places: places)).toEntity();
}
