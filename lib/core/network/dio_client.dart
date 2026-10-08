import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import '../storage/token_storage.dart';
import '../utils/app_logger.dart';
import 'auth_interceptor.dart';

BaseOptions _baseOptions() => BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: Env.connectTimeout,
      receiveTimeout: Env.receiveTimeout,
      headers: {'Accept': 'application/json'},
    );

/// Signal émis quand la session ne peut plus être rafraîchie.
/// Le routeur l'écoutera (Sprint S1) pour renvoyer vers la connexion.
final sessionExpiredProvider = NotifierProvider<SessionExpiredNotifier, int>(SessionExpiredNotifier.new);

class SessionExpiredNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void notify() => state++;
}

/// Client HTTP unique de l'application. Les datasources le reçoivent par ce provider.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(_baseOptions());
  dio.interceptors.add(
    AuthInterceptor(
      tokenStorage: ref.watch(tokenStorageProvider),
      refreshClient: Dio(_baseOptions()),
      onSessionExpired: () => ref.read(sessionExpiredProvider.notifier).notify(),
    ),
  );
  if (Env.isDev) {
    dio.interceptors.add(
      LogInterceptor(
        requestHeader: false,
        responseHeader: false,
        // Jamais de corps en log : il peut contenir le code de départ ou des données KYC.
        requestBody: false,
        responseBody: false,
        logPrint: (o) => appLogger.d(o),
      ),
    );
  }
  return dio;
});
