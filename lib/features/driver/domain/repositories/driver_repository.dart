import '../../../trip/domain/entities/geo_place.dart';
import '../../../vehicle/domain/entities/vehicle.dart';
import '../entities/driver_trip.dart';

/// Espace conducteur (docs/api/driver.md). Toutes les règles (prix, places, droits) sont côté backend.
abstract interface class DriverRepository {
  Future<PriceEstimate> estimatePrice({
    required GeoPlace depart,
    required GeoPlace arrivee,
    required List<GeoPlace> pickupPoints,
    required VehicleType vehicleType,
  });

  Future<DriverTrip> publish(TripDraft draft);

  Future<List<DriverTrip>> myTrips();

  Future<DriverTrip> trip(int id);

  Future<DriverTrip> cancelTrip(int id);

  Future<DriverTrip> finishTrip(int id);

  Future<void> accept(int bookingId);

  Future<void> refuse(int bookingId);

  /// Code de départ donné par le passager (CA7). `BadRequestApiException` si incorrect.
  Future<void> submitDepartureCode(int bookingId, String code);

  /// Absence du passager, avec la position du conducteur comme preuve (CA9).
  Future<void> declareAbsence(int bookingId, {required double lat, required double lng});

  Future<DriverSavings> savings();
}
