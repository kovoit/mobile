import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fake_backend.dart';

final fakeNotificationsProvider =
    Provider<FakeNotifications>((ref) => FakeNotifications(ref.watch(fakeBackendProvider)));

/// Notifications simulées (`Env.useMockApi`), au format du backend (NotificationSerializer).
/// Alimentées par les événements simulés (réservation acceptée, refusée…).
class FakeNotifications {
  FakeNotifications(this._backend);

  final FakeBackend _backend;

  Future<List<Map<String, dynamic>>> list() async {
    await _backend.wait();
    return [..._backend.notifications.reversed];
  }

  Future<int> unreadCount() async {
    await _backend.wait();
    return _backend.notifications.where((n) => n['lue_le'] == null).length;
  }

  Future<void> markRead(String id) async {
    await _backend.wait();
    for (final n in _backend.notifications.where((n) => n['id'] == id && n['lue_le'] == null)) {
      n['lue_le'] = _backend.clock().toUtc().toIso8601String();
    }
  }

  Future<void> markAllRead() async {
    await _backend.wait();
    for (final n in _backend.notifications.where((n) => n['lue_le'] == null)) {
      n['lue_le'] = _backend.clock().toUtc().toIso8601String();
    }
  }
}
