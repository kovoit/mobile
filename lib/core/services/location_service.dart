import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Résultat d'une demande de position.
sealed class LocationResult {
  const LocationResult();
}

final class LocationFound extends LocationResult {
  const LocationFound(this.lat, this.lng);

  final double lat;
  final double lng;
}

/// Localisation désactivée, permission refusée, ou position introuvable.
final class LocationUnavailable extends LocationResult {
  const LocationUnavailable(this.message);

  final String message;
}

/// Position actuelle de l'appareil, au premier plan uniquement (aucun suivi en arrière-plan dans le MVP).
abstract interface class LocationService {
  Future<LocationResult> currentPosition();
}

class GeolocatorLocationService implements LocationService {
  @override
  Future<LocationResult> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationUnavailable('Activez la localisation de votre téléphone.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return const LocationUnavailable('Autorisez Kovoit à accéder à votre position.');
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
      );
      return LocationFound(position.latitude, position.longitude);
    } on Exception {
      return const LocationUnavailable('Position introuvable. Réessayez à découvert.');
    }
  }
}

final locationServiceProvider = Provider<LocationService>((ref) => GeolocatorLocationService());
