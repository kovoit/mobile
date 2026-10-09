import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../datasources/vehicle_remote_data_source.dart';
import '../dto/vehicle_dto.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  VehicleRepositoryImpl(this._remote);

  final VehicleRemoteDataSource _remote;

  @override
  Future<Vehicle?> fetchMine() async => (await _remote.fetchMine())?.toEntity();

  @override
  Future<Vehicle> save(Vehicle vehicle) async => (await _remote.save(VehicleDto.fromEntity(vehicle))).toEntity();
}
