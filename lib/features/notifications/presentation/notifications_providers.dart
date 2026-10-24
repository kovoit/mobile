import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/mock/fake_notifications.dart';
import '../../../core/network/api_service.dart';
import '../data/notifications_remote_data_source.dart';
import '../domain/app_notification.dart';

final notificationsRemoteDataSourceProvider = Provider<NotificationsRemoteDataSource>((ref) {
  if (Env.useMockApi) return FakeNotificationsRemoteDataSource(ref.watch(fakeNotificationsProvider));
  return ApiNotificationsRemoteDataSource(ref.watch(apiServiceProvider));
});

final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>(
  (ref) => ref.watch(notificationsRemoteDataSourceProvider).list(),
);

/// Pastille du Profil. En cas d'erreur : 0 (pas de chiffre inventé, l'écran affichera l'erreur).
final unreadNotificationsProvider = FutureProvider.autoDispose<int>((ref) async {
  try {
    return await ref.watch(notificationsRemoteDataSourceProvider).unreadCount();
  } on Object {
    return 0;
  }
});
