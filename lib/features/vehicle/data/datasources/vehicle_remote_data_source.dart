import 'package:dio/dio.dart';

import '../../../../core/mock/fake_backend.dart';
import '../../../../core/network/api_exception.dart';
import '../dto/vehicle_dto.dart';

abstract interface class VehicleRemoteDataSource {
  Future<VehicleDto?> fetchMine();

  Future<VehicleDto> save(VehicleDto vehicle);
}

class DioVehicleRemoteDataSource implements VehicleRemoteDataSource {
  DioVehicleRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<VehicleDto?> fetchMine() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/vehicules/moi/');
      return VehicleDto.fromJson(res.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<VehicleDto> save(VehicleDto vehicle) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>('/vehicules/moi/', data: vehicle.toJson());
      return VehicleDto.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
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
    final maxPlaces = vehicle.type == 'moto' ? 2 : 9;
    if (vehicle.nbPlaces < 2 || vehicle.nbPlaces > maxPlaces) {
      throw BadRequestApiException(
        'Nombre de places invalide.',
        fieldErrors: {'nb_places': 'Entre 2 et $maxPlaces places, conducteur compris.'},
      );
    }
    _backend.saveVehicle(id, vehicle.toJson());
    return VehicleDto.fromJson(_backend.vehicleJson(id)!);
  }
}
