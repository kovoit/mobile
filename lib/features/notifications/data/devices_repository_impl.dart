import '../../../core/constants/api_constants.dart';
import '../../../core/mock/fake_after_trip.dart';
import '../../../core/network/api_service.dart';
import '../domain/devices_repository.dart';

/// `POST /notifications/appareils/` et `DELETE /notifications/appareils/{jeton}/`.
class ApiDevicesRepository implements DevicesRepository {
  const ApiDevicesRepository(this._api);

  final ApiService _api;

  @override
  Future<void> registerDevice({required String token, required String platform}) =>
      _api.post<void>(ApiEndpoints.appareils, body: {'jeton': token, 'plateforme': platform}, parse: (_) {});

  @override
  Future<void> unregisterDevice(String token) => _api.delete(ApiEndpoints.appareil(token));
}

/// Fausse API (`Env.useMockApi`).
class FakeDevicesRepository implements DevicesRepository {
  FakeDevicesRepository(this._fake);

  final FakeAfterTrip _fake;

  @override
  Future<void> registerDevice({required String token, required String platform}) => _fake.registerDevice(token);

  @override
  Future<void> unregisterDevice(String token) => _fake.unregisterDevice(token);
}
