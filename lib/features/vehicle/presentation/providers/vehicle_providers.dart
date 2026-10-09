import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/mock/fake_backend.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/session_controller.dart';
import '../../data/datasources/vehicle_remote_data_source.dart';
import '../../data/repositories/vehicle_repository_impl.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/vehicle_repository.dart';

final vehicleRemoteDataSourceProvider = Provider<VehicleRemoteDataSource>((ref) {
  if (Env.useMockApi) return FakeVehicleRemoteDataSource(ref.watch(fakeBackendProvider));
  return DioVehicleRemoteDataSource(ref.watch(dioProvider));
});

final vehicleRepositoryProvider =
    Provider<VehicleRepository>((ref) => VehicleRepositoryImpl(ref.watch(vehicleRemoteDataSourceProvider)));

/// Véhicule déclaré par l'utilisateur connecté (`null` si aucun).
class MyVehicleController extends AsyncNotifier<Vehicle?> {
  @override
  Future<Vehicle?> build() {
    ref.watch(sessionControllerProvider.select((s) => s.value?.id));
    return ref.read(vehicleRepositoryProvider).fetchMine();
  }

  /// Enregistre puis relit l'utilisateur (`vehicule_declare` débloque le mode conducteur).
  Future<void> save(Vehicle vehicle) async {
    state = AsyncData(await ref.read(vehicleRepositoryProvider).save(vehicle));
    await ref.read(sessionControllerProvider.notifier).refreshUser();
  }
}

final myVehicleProvider = AsyncNotifierProvider<MyVehicleController, Vehicle?>(MyVehicleController.new);
