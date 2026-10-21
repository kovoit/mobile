import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../../core/router/routes.dart';
import '../../../core/services/push_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../auth/presentation/providers/session_controller.dart';
import 'notifications_providers.dart';

/// Route à ouvrir pour une cible de notification (push touché ou ligne de la liste).
String? notificationRoute({int? bookingId, int? tripId, String? type}) {
  if (bookingId != null) return Routes.booking(bookingId);
  if (tripId != null) return Routes.driverTrip(tripId);
  if (type != null && type.startsWith('kyc_')) return Routes.profile;
  return null;
}

/// Relie le push (FCM) à l'application :
/// - enregistre l'appareil quand l'utilisateur est connecté et vérifié ;
/// - relit les notifications à chaque push reçu ;
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
          .read(notificationsRepositoryProvider)
          .registerDevice(token: token, platform: platform)
          .catchError((Object e) => appLogger.w('Enregistrement de l’appareil impossible : $e')),
      onMessage: (_) => _ref.read(notificationsProvider.notifier).refresh(),
      onOpened: (data) {
        _ref.read(notificationsProvider.notifier).refresh();
        final route = notificationRoute(
          bookingId: int.tryParse(data['reservation_id'] ?? ''),
          tripId: int.tryParse(data['trajet_id'] ?? ''),
          type: data['type'],
        );
        if (route != null) _ref.read(appRouterProvider).push(route);
      },
    );
  }

  /// Déconnexion : on arrête l'écoute. Le serveur oublie aussi les jetons invalides.
  Future<void> _stop() async {
    if (!_started) return;
    _started = false;
    final token = await _push.currentToken();
    if (token != null) {
      await _ref.read(notificationsRepositoryProvider).unregisterDevice(token).catchError((Object _) {});
    }
    await _push.stop();
  }
}

final pushCoordinatorProvider = Provider<PushCoordinator>(PushCoordinator.new);
