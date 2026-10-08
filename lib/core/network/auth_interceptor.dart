import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// Ajoute le JWT à chaque requête et tente un rafraîchissement sur 401.
/// En cas d'échec du refresh, les tokens sont effacés et [onSessionExpired] est appelé.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this._tokenStorage,
    required this._refreshClient,
    this.onSessionExpired,
  });

  final TokenStorage _tokenStorage;

  /// Client séparé (sans cet intercepteur) pour éviter une boucle de refresh.
  final Dio _refreshClient;
  final void Function()? onSessionExpired;

  static const refreshPath = '/auth/token/refresh/';

  /// Marqueur pour ne pas rejouer indéfiniment une requête.
  static const _retriedKey = 'auth_retried';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenStorage.readAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra[_retriedKey] == true;
    if (!isUnauthorized || alreadyRetried) {
      return handler.next(err);
    }

    final newAccess = await _refreshAccessToken();
    if (newAccess == null) {
      await _tokenStorage.clear();
      onSessionExpired?.call();
      return handler.next(err);
    }

    try {
      final options = err.requestOptions
        ..headers['Authorization'] = 'Bearer $newAccess'
        ..extra[_retriedKey] = true;
      final response = await _refreshClient.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<String?> _refreshAccessToken() async {
    final refresh = await _tokenStorage.readRefreshToken();
    if (refresh == null) return null;
    try {
      final response = await _refreshClient.post<Map<String, dynamic>>(
        refreshPath,
        data: {'refresh': refresh},
      );
      final access = response.data?['access'] as String?;
      if (access == null) return null;
      await _tokenStorage.saveTokens(
        access: access,
        refresh: response.data?['refresh'] as String?,
      );
      return access;
    } on DioException {
      return null;
    }
  }
}
