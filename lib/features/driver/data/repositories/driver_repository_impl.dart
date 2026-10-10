import '../../../trip/data/dto/trip_dto.dart';
import '../../../trip/domain/entities/geo_place.dart';
import '../../../vehicle/domain/entities/vehicle.dart';
import '../../domain/entities/driver_trip.dart';
import '../../domain/repositories/driver_repository.dart';
import '../datasources/driver_remote_data_source.dart';

class DriverRepositoryImpl implements DriverRepository {
  DriverRepositoryImpl(this._remote);

  final DriverRemoteDataSource _remote;

  static Map<String, dynamic> _place(GeoPlace place) => GeoPlaceDto.fromEntity(place).toJson();

  @override
  Future<PriceEstimate> estimatePrice({
    required GeoPlace depart,
    required GeoPlace arrivee,
    required List<GeoPlace> pickupPoints,
    required VehicleType vehicleType,
  }) async =>
      (await _remote.estimate({
        'depart': _place(depart),
        'arrivee': _place(arrivee),
        'points_prise_en_charge': [for (final p in pickupPoints) _place(p)],
        'type_vehicule': vehicleType.apiValue,
      }))
          .toEntity();

  @override
  Future<DriverTrip> publish(TripDraft draft) async => (await _remote.publish({
        'depart': _place(draft.depart),
        'arrivee': _place(draft.arrivee),
        'points_prise_en_charge': [for (final p in draft.pickupPoints) _place(p)],
        'depart_le': draft.departureAt.toUtc().toIso8601String(),
        'places_total': draft.places,
      }))
          .toEntity();

  @override
  Future<List<DriverTrip>> myTrips() async => [for (final dto in await _remote.myTrips()) dto.toEntity()];

  @override
  Future<DriverTrip> trip(int id) async => (await _remote.trip(id)).toEntity();

  @override
  Future<DriverTrip> cancelTrip(int id) async => (await _remote.cancelTrip(id)).toEntity();

  @override
  Future<DriverTrip> finishTrip(int id) async => (await _remote.finishTrip(id)).toEntity();

  @override
  Future<void> accept(int bookingId) => _remote.accept(bookingId);

  @override
  Future<void> refuse(int bookingId) => _remote.refuse(bookingId);

  @override
  Future<void> submitDepartureCode(int bookingId, String code) => _remote.submitCode(bookingId, code);

  @override
  Future<void> declareAbsence(int bookingId, {required double lat, required double lng}) =>
      _remote.declareAbsence(bookingId, lat: lat, lng: lng);

  @override
  Future<DriverSavings> savings() async => (await _remote.savings()).toEntity();
}
