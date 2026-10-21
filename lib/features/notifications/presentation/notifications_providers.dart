import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/mock/fake_after_trip.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/presentation/providers/session_controller.dart';
import '../../booking/presentation/providers/booking_providers.dart';
import '../../driver/presentation/providers/driver_providers.dart';
import '../data/notifications_repository_impl.dart';
import '../domain/app_notification.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  if (Env.useMockApi) return FakeNotificationsRepository(ref.watch(fakeAfterTripProvider));
  return DioNotificationsRepository(ref.watch(dioProvider));
});

/// Notifications de l'utilisateur connecté (cloche de l'en-tête).
///
/// Sans push (dev, ou Firebase non configuré), la liste est relue toutes les [pollInterval].
/// À chaque nouvelle notification, les écrans concernés (réservation, trajet publié, profil)
/// sont rafraîchis : c'est ce qui remplace progressivement le sondage des écrans de suivi.
class NotificationsController extends AsyncNotifier<List<AppNotification>> {
  static const Duration pollInterval = Duration(seconds: 60);

  Set<int> _known = {};

  NotificationsRepository get _repository => ref.read(notificationsRepositoryProvider);

  @override
  Future<List<AppNotification>> build() async {
    final user = ref.watch(sessionControllerProvider.select((s) => s.value));
    if (user == null || !user.profilComplet) return const [];

    if (!Env.pushEnabled) {
      final timer = Timer.periodic(pollInterval, (_) => refresh());
      ref.onDispose(timer.cancel);
    }
    final list = await _repository.list();
    _known = {for (final n in list) n.id};
    return list;
  }

  /// Relecture silencieuse ; les nouveautés rafraîchissent les écrans concernés.
  Future<void> refresh() async {
    try {
      final list = await _repository.list();
      final fresh = list.where((n) => !_known.contains(n.id)).toList();
      _known = {for (final n in list) n.id};
      state = AsyncData(list);
      for (final n in fresh) {
        _refreshTargets(n);
      }
    } on Object {
      // Prochaine relecture.
    }
  }

  void _refreshTargets(AppNotification n) {
    if (n.bookingId != null) {
      ref.invalidate(bookingProvider(n.bookingId!));
      ref.read(myBookingsProvider.notifier).refresh();
    }
    if (n.tripId != null) {
      ref.invalidate(driverTripProvider(n.tripId!));
      ref.read(myDriverTripsProvider.notifier).refresh();
    }
    if (n.concernsKyc) ref.read(sessionControllerProvider.notifier).refreshUser();
  }

  Future<void> markRead(AppNotification notification) async {
    if (notification.read) return;
    await _repository.markRead([notification.id]);
    await refresh();
  }

  Future<void> markAllRead() async {
    await _repository.markRead();
    await refresh();
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsController, List<AppNotification>>(NotificationsController.new);

/// Nombre de notifications non lues (pastille de la cloche).
final unreadNotificationsProvider = Provider<int>(
  (ref) => ref.watch(notificationsProvider).value?.where((n) => !n.read).length ?? 0,
);
