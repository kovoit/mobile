import '../entities/vehicle.dart';

abstract interface class VehicleRepository {
  /// `null` si aucun véhicule n'est déclaré.
  Future<Vehicle?> fetchMine();

  /// Déclare ou met à jour le véhicule (un seul véhicule par conducteur dans le MVP).
  Future<Vehicle> save(Vehicle vehicle);
}
