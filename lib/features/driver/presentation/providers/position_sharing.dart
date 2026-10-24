import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/clock.dart';
import '../../../auth/presentation/providers/session_controller.dart';
import 'driver_providers.dart';

/// Partage de la position du conducteur (« Partager mon trajet ») pendant un trajet.
class PositionSharingState {
  const PositionSharingState({this.tripId, this.unavailable = false});

  /// Trajet dont la position est partagée (null : aucun partage en cours).
  final String? tripId;

  /// Localisation refusée ou coupée : on n'insiste pas (pas de demande en boucle).
  final bool unavailable;
}

/// Lié au trajet, pas à l'écran : le partage continue quand le conducteur quitte l'écran ou
/// met l'application en arrière-plan (service de premier plan Android, avec sa notification ;
/// mode arrière-plan iOS). Il s'arrête à la fin du trajet, à la déconnexion, ou si le backend
/// refuse (trajet clos). Une position au plus toutes les [interval] est envoyée.
class PositionSharing extends Notifier<PositionSharingState> {
  static const Duration interval = Duration(seconds: 30);

  StreamSubscription<LocationResult>? _subscription;
  DateTime? _lastSent;
  bool _sending = false;

  @override
  PositionSharingState build() {
    ref.onDispose(() => _subscription?.cancel());
    ref.listen(sessionControllerProvider.select((s) => s.value?.id), (_, userId) {
      if (userId == null) stop();
    });
    return const PositionSharingState();
  }

  void start(String tripId) {
    if (state.tripId == tripId) return;
    stop();
    state = PositionSharingState(tripId: tripId);
    _subscription = ref.read(locationServiceProvider).track(interval: interval).listen((r) => _onPosition(tripId, r));
  }

  Future<void> _onPosition(String tripId, LocationResult result) async {
    switch (result) {
      case LocationUnavailable():
        unawaited(_subscription?.cancel());
        _subscription = null;
        state = PositionSharingState(tripId: tripId, unavailable: true);
      case LocationFound(:final lat, :final lng):
        final now = ref.read(clockProvider)();
        if (_sending || (_lastSent != null && now.difference(_lastSent!) < interval)) return;
        _sending = true;
        try {
          await ref.read(driverRepositoryProvider).sendPosition(tripId, lat: lat, lng: lng);
          _lastSent = now;
        } on ConflictApiException {
          stop(); // trajet terminé ou annulé côté serveur
        } on ApiException {
          // Réseau : la position suivante sera envoyée.
        } finally {
          _sending = false;
        }
    }
  }

  void stop() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    _lastSent = null;
    if (state.tripId != null) state = const PositionSharingState();
  }
}

final positionSharingProvider =
    NotifierProvider<PositionSharing, PositionSharingState>(PositionSharing.new);
