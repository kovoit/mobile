import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/mock/fake_after_trip.dart';
import '../../../core/network/api_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/router/routes.dart';
import '../../../core/services/push_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../auth/presentation/providers/session_controller.dart';
import '../../booking/presentation/providers/booking_providers.dart';
import '../../driver/presentation/providers/driver_providers.dart';
import '../data/devices_repository_impl.dart';
import '../domain/devices_repository.dart';

final devicesRepositoryProvider = Provider<DevicesRepository>((ref) {
  if (Env.useMockApi) return FakeDevicesRepository(ref.watch(fakeAfterTripProvider));
  return ApiDevicesRepository(ref.watch(apiServiceProvider));
});

/// Relit les écrans dont l'état a pu changer côté serveur (push reçu, retour au premier plan).
void refreshServerState(Ref ref) {
  ref.read(myBookingsProvider.notifier).refresh();
  ref.read(myDriverTripsProvider.notifier).refresh();
  ref.read(sessionControllerProvider.notifier).refreshUser();
}

/// Écran à ouvrir quand un push est touché : le backend envoie `reservation_id`.
String pushRoute({required Map<String, String> data, required bool driverMode}) {
  final bookingId = data['reservation_id'];
  if (bookingId == null || bookingId.isEmpty) return Routes.myTrips;
  // Le conducteur gère ses réservations depuis le trajet publié (onglet Mes trajets).
  return driverMode ? Routes.myTrips : Routes.booking(bookingId);
}

/// Relie le push (FCM) à l'application :
/// - enregistre l'appareil quand l'utilisateur est connecté et vérifié ;
/// - relit l'état serveur à chaque push reçu ;
/// - ouvre l'écran concerné quand un push est touché.
/// Sans push configuré ([NoopPushService]), ne fait rien.
class PushCoordinator {
  PushCoordinator(this._ref) {
    _ref.listen(
      sessionControllerProvider.select((s) => s.value?.profilComplet == true ? s.value?.id : null),
      (_, userId) => userId == null ? _stop() : _start(),
      fireImmediately: true,
    );
  }

  final Ref _ref;
  bool _started = false;

  PushService get _push => _ref.read(pushServiceProvider);

  Future<void> _start() async {
    if (_started) return;
    _started = true;
    await _push.start(
      onToken: (token, platform) => _ref
          .read(devicesRepositoryProvider)
          .registerDevice(token: token, platform: platform)
          .catchError((Object e) => appLogger.w('Enregistrement de l’appareil impossible : $e')),
      onMessage: (_) => refreshServerState(_ref),
      onOpened: (data) {
        refreshServerState(_ref);
        final driverMode = _ref.read(sessionControllerProvider).value?.isDriverMode ?? false;
        _ref.read(appRouterProvider).push(pushRoute(data: data, driverMode: driverMode));
      },
    );
  }

  /// Déconnexion : on arrête l'écoute. Le serveur oublie aussi les jetons invalides.
  Future<void> _stop() async {
    if (!_started) return;
    _started = false;
    final token = await _push.currentToken();
    if (token != null) {
      await _ref.read(devicesRepositoryProvider).unregisterDevice(token).catchError((Object _) {});
    }
    await _push.stop();
  }
}

final pushCoordinatorProvider = Provider<PushCoordinator>(PushCoordinator.new);
