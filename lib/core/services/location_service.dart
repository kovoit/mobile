import 'dart:async';

import 'package:flutter/foundation.dart';
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

/// Position de l'appareil : ponctuelle (déclaration d'absence) ou suivie pendant un trajet.
abstract interface class LocationService {
  Future<LocationResult> currentPosition();

  /// Positions successives pendant un trajet, y compris application en arrière-plan (service de
  /// premier plan Android avec notification, mode arrière-plan iOS). Émet une seule fois
  /// [LocationUnavailable] si la localisation est coupée ou refusée.
  Stream<LocationResult> track({required Duration interval});
}

class GeolocatorLocationService implements LocationService {
  /// Autorisation « pendant l'utilisation » suffisante : le suivi démarre au premier plan.
  Future<LocationUnavailable?> _access() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationUnavailable('Activez la localisation de votre téléphone.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return const LocationUnavailable('Autorisez Kovoit à accéder à votre position.');
    }
    return null;
  }

  @override
  Stream<LocationResult> track({required Duration interval}) async* {
    final refused = await _access();
    if (refused != null) {
      yield refused;
      return;
    }
    final LocationSettings settings = switch (defaultTargetPlatform) {
      TargetPlatform.android => AndroidSettings(
          accuracy: LocationAccuracy.high,
          intervalDuration: interval,
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: 'Kovoit partage votre position',
            notificationText: 'Pendant votre trajet, pour les proches de vos passagers.',
            notificationChannelName: 'Partage du trajet',
            setOngoing: true,
          ),
        ),
      TargetPlatform.iOS => AppleSettings(
          accuracy: LocationAccuracy.high,
          activityType: ActivityType.automotiveNavigation,
          showBackgroundLocationIndicator: true,
        ),
      _ => const LocationSettings(accuracy: LocationAccuracy.high),
    };
    yield* Geolocator.getPositionStream(locationSettings: settings)
        .map<LocationResult>((p) => LocationFound(p.latitude, p.longitude))
        .transform(StreamTransformer<LocationResult, LocationResult>.fromHandlers(
          handleError: (error, stack, sink) =>
              sink.add(const LocationUnavailable('Position introuvable : partage interrompu.')),
        ));
  }

  @override
  Future<LocationResult> currentPosition() async {
    final refused = await _access();
    if (refused != null) return refused;
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
