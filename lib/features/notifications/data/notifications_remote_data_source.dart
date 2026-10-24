import '../../../core/constants/api_constants.dart';
import '../../../core/mock/fake_notifications.dart';
import '../../../core/network/api_service.dart';
import '../domain/app_notification.dart';

abstract interface class NotificationsRemoteDataSource {
  /// Première page, plus récentes d'abord.
  Future<List<AppNotification>> list();

  Future<int> unreadCount();

  Future<void> markRead(String id);

  Future<void> markAllRead();
}

class ApiNotificationsRemoteDataSource implements NotificationsRemoteDataSource {
  const ApiNotificationsRemoteDataSource(this._api);

  final ApiService _api;

  @override
  Future<List<AppNotification>> list() async =>
      (await _api.getPage(ApiEndpoints.notifications, pageSize: 50, item: AppNotification.fromJson)).results;

  @override
  Future<int> unreadCount() => _api.get(
        ApiEndpoints.notificationsNonLues,
        parse: (json) => ApiService.asMap(json)['nombre'] as int,
      );

  @override
  Future<void> markRead(String id) => _api.post<void>(ApiEndpoints.notificationLue(id), parse: (_) {});

  @override
  Future<void> markAllRead() => _api.post<void>(ApiEndpoints.notificationsToutLire, parse: (_) {});
}

class FakeNotificationsRemoteDataSource implements NotificationsRemoteDataSource {
  FakeNotificationsRemoteDataSource(this._fake);

  final FakeNotifications _fake;

  @override
  Future<List<AppNotification>> list() async => [for (final j in await _fake.list()) AppNotification.fromJson(j)];

  @override
  Future<int> unreadCount() => _fake.unreadCount();

  @override
  Future<void> markRead(String id) => _fake.markRead(id);

  @override
  Future<void> markAllRead() => _fake.markAllRead();
}
