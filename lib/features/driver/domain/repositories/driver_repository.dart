import '../entities/driver_trip.dart';

/// Espace conducteur. Toutes les règles (prix, places, droits) sont côté backend.
abstract interface class DriverRepository {
  /// Le prix par place est fixé par Kovoit et renvoyé dans le trajet publié.
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

  Future<DriverSavings> savings();
}
