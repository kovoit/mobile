import '../../../../core/constants/api_constants.dart';
import '../../../../core/mock/fake_wallet.dart';
import '../../../../core/mock/fake_trips.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_service.dart';
import '../dto/trip_dto.dart';

abstract interface class TripRemoteDataSource {
  /// `GET /trajets/{id}/` : le trajet et l'aperçu du paiement pour l'utilisateur connecté.
  Future<TripDto> fetchTrip(String id);
}

class ApiTripRemoteDataSource implements TripRemoteDataSource {
  const ApiTripRemoteDataSource(this._api);

  final ApiService _api;

  @override
  Future<TripDto> fetchTrip(String id) =>
      _api.get(ApiEndpoints.trajet(id), parse: (json) => TripDto.fromJson(ApiService.asMap(json)));
}

/// Fausse API trajets (`Env.useMockApi`), au format du backend : l'aperçu du paiement suit le
/// portefeuille simulé de l'utilisateur connecté.
class FakeTripRemoteDataSource implements TripRemoteDataSource {
  FakeTripRemoteDataSource(this._wallet);

  final FakeWallet _wallet;

  @override
  Future<TripDto> fetchTrip(String id) async {
    final balance = await _wallet.balance();
    final json = FakeTrips.tripById(id, soldeDisponible: balance['disponible']!);
    if (json == null) throw const NotFoundApiException('Ce trajet n’est plus disponible.');
    return TripDto.fromJson(json);
  }
}
