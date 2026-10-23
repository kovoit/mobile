import '../../../trip/domain/entities/geo_place.dart';
import '../entities/driver_trip.dart';
import '../entities/price_breakdown.dart';

/// Données d'une estimation : record (égalité par valeur) utilisable comme clé de provider.
typedef EstimateQuery = ({String vehiculeId, GeoPlace depart, GeoPlace arrivee, int places});

/// Espace conducteur. Toutes les règles (prix, places, droits) sont côté backend.
abstract interface class DriverRepository {
  /// Prix calculé par Kovoit avant publication (`BadRequestApiException` PLACES_INVALIDES…).
  Future<PriceBreakdown> estimate(EstimateQuery query);

  /// Le prix par place est calculé par Kovoit et figé dans le trajet publié.
  Future<DriverTrip> publish(TripDraft draft, {required String vehiculeId});

  Future<List<DriverTrip>> myTrips();

  /// Le trajet et ses demandes.
  Future<DriverTrip> trip(String id);

  Future<DriverTrip> cancelTrip(String id);

  Future<DriverTrip> finishTrip(String id);

  Future<void> accept(String bookingId);

  Future<void> refuse(String bookingId);

  /// Code de départ donné par le passager. `BadRequestApiException` si incorrect.
  Future<void> submitDepartureCode(String bookingId, String code);

  /// Absence du passager, avec la position du conducteur comme preuve.
  Future<void> declareAbsence(String bookingId, {required double lat, required double lng});

  /// Position GPS du conducteur pendant le trajet (partage avec les proches des passagers).
  Future<void> sendPosition(String tripId, {required double lat, required double lng});

  Future<DriverSavings> savings();
}
