import '../../../../core/constants/api_constants.dart';
import '../../../../core/mock/fake_backend.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_service.dart';
import '../dto/vehicle_dto.dart';

abstract interface class VehicleRemoteDataSource {
  /// Premier véhicule déclaré (un seul par conducteur dans le MVP), `null` si aucun.
  Future<VehicleDto?> fetchMine();

  /// Création (`POST /vehicules/`) ou modification (`PATCH /vehicules/{id}/`).
  Future<VehicleDto> save(VehicleDto vehicle);
}

class ApiVehicleRemoteDataSource implements VehicleRemoteDataSource {
  const ApiVehicleRemoteDataSource(this._api);

  final ApiService _api;

  static VehicleDto _vehicle(Object? json) => VehicleDto.fromJson(ApiService.asMap(json));

  @override
  Future<VehicleDto?> fetchMine() async {
    final vehicles = await _api.get(
      ApiEndpoints.vehicules,
      parse: (json) => [for (final item in ApiService.asList(json)) _vehicle(item)],
    );
    return vehicles.firstOrNull;
  }

  @override
  Future<VehicleDto> save(VehicleDto vehicle) => vehicle.id == null
      ? _api.post(ApiEndpoints.vehicules, body: vehicle.toRequest(), parse: _vehicle)
      : _api.patch(ApiEndpoints.vehicule(vehicle.id!), body: vehicle.toRequest(), parse: _vehicle);
}

/// Fausse API véhicule (`Env.useMockApi`) branchée sur le [FakeBackend] partagé.
class FakeVehicleRemoteDataSource implements VehicleRemoteDataSource {
  FakeVehicleRemoteDataSource(this._backend);

  final FakeBackend _backend;

  @override
  Future<VehicleDto?> fetchMine() async {
    await _backend.wait();
    final json = _backend.vehicleJson(await _backend.currentUserId());
    return json == null ? null : VehicleDto.fromJson(json);
  }

  @override
  Future<VehicleDto> save(VehicleDto vehicle) async {
    await _backend.wait();
    final id = await _backend.currentUserId();
    final maxPlaces = vehicle.typeVehicule == 'moto' ? 2 : 9;
    if (vehicle.nbPlaces < 2 || vehicle.nbPlaces > maxPlaces) {
      throw BadRequestApiException(
        'Les données envoyées sont invalides.',
        code: 'DONNEES_INVALIDES',
        fieldErrors: {'nb_places': 'Entre 2 et $maxPlaces places, conducteur compris.'},
      );
    }
    _backend.saveVehicle(id, vehicle.toRequest());
    return VehicleDto.fromJson(_backend.vehicleJson(id)!);
  }
}
