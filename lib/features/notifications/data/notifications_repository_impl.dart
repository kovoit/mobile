import 'package:dio/dio.dart';

import '../../../core/mock/fake_after_trip.dart';
import '../../../core/network/api_exception.dart';
import '../domain/app_notification.dart';
import 'notification_dto.dart';

class DioNotificationsRepository implements NotificationsRepository {
  DioNotificationsRepository(this._dio);

  final Dio _dio;

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<List<AppNotification>> list() => _call(() async {
        final res = await _dio.get<List<dynamic>>('/notifications/');
        return [for (final item in res.data!) NotificationDto.fromJson(item as Map<String, dynamic>).toEntity()];
      });

  @override
  Future<void> markRead([List<int>? ids]) =>
      _call(() => _dio.post<dynamic>('/notifications/lues/', data: {'ids': ?ids}));

  @override
  Future<void> registerDevice({required String token, required String platform}) =>
      _call(() => _dio.post<dynamic>('/appareils/', data: {'token': token, 'plateforme': platform}));

  @override
  Future<void> unregisterDevice(String token) => _call(() => _dio.delete<dynamic>('/appareils/$token/'));
}

/// Fausse API (`Env.useMockApi`).
class FakeNotificationsRepository implements NotificationsRepository {
  FakeNotificationsRepository(this._fake);

  final FakeAfterTrip _fake;

  @override
  Future<List<AppNotification>> list() async =>
      [for (final json in await _fake.notifications()) NotificationDto.fromJson(json).toEntity()];

  @override
  Future<void> markRead([List<int>? ids]) => _fake.markRead(ids);

  @override
  Future<void> registerDevice({required String token, required String platform}) => _fake.registerDevice(token);

  @override
  Future<void> unregisterDevice(String token) => _fake.unregisterDevice(token);
}
