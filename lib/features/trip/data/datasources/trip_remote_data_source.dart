import '../../../../core/constants/api_constants.dart';
import '../../../../core/mock/fake_wallet.dart';
import '../../../../core/mock/fake_trips.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_service.dart';
import '../../domain/repositories/trip_repository.dart' show TripQuery;
import '../dto/trip_dto.dart';

abstract interface class TripRemoteDataSource {
  /// `GET /trajets/{id}/` : le trajet et l'aperçu du paiement pour l'utilisateur connecté.
  /// Avec le point de prise en charge et l'arrivée : prix du passager (sa part du trajet).
  Future<TripDto> fetchTrip(TripQuery query);
}


class ApiTripRemoteDataSource implements TripRemoteDataSource {
  const ApiTripRemoteDataSource(this._api);

  final ApiService _api;

  @override
  Future<TripDto> fetchTrip(TripQuery q) => _api.get(
        ApiEndpoints.trajet(q.id),
        query: q.pickupId == null || q.arriveeLat == null || q.arriveeLng == null
            ? null
            : {'point_id': q.pickupId, 'arrivee_lat': q.arriveeLat, 'arrivee_lng': q.arriveeLng},
        parse: (json) => TripDto.fromJson(ApiService.asMap(json)),
      );
}

/// Fausse API trajets (`Env.useMockApi`), au format du backend : l'aperçu du paiement suit le
/// portefeuille simulé de l'utilisateur connecté.
class FakeTripRemoteDataSource implements TripRemoteDataSource {
  FakeTripRemoteDataSource(this._wallet);

  final FakeWallet _wallet;

  @override
  Future<TripDto> fetchTrip(TripQuery q) async {
    final balance = await _wallet.balance();
    final json = FakeTrips.tripById(q.id, soldeDisponible: balance['disponible']!);
    if (json == null) throw const NotFoundApiException('Ce trajet n’est plus disponible.');
    return TripDto.fromJson(json);
  }
}
