import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

/// Ajoute le JWT à chaque requête et tente un rafraîchissement sur 401.
/// En cas d'échec du refresh, les tokens sont effacés et [onSessionExpired] est appelé.
///
/// Le backend fait tourner le jeton de rafraîchissement (rotation + liste noire) :
/// chaque refresh renvoie un nouveau `refresh`, qui remplace l'ancien.
/// [QueuedInterceptor] garantit qu'un seul refresh est en vol à la fois.
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

  static const refreshPath = ApiEndpoints.jetonRafraichir;

  /// Marqueur pour ne pas rejouer indéfiniment une requête.
  static const _retriedKey = 'auth_retried';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenStorage.readAccessToken();
    if (token != null && !ApiEndpoints.sansRafraichissement.contains(options.path)) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final isUnauthorized = err.response?.statusCode == 401;
    final alreadyRetried = options.extra[_retriedKey] == true;
    if (!isUnauthorized || alreadyRetried || ApiEndpoints.sansRafraichissement.contains(options.path)) {
      return handler.next(err);
    }

    // Une requête précédente de la file a peut-être déjà rafraîchi le jeton : on le réutilise.
    final current = await _tokenStorage.readAccessToken();
    final sentWith = options.headers['Authorization'];
    final newAccess = current != null && sentWith != 'Bearer $current' ? current : await _refreshAccessToken();
    if (newAccess == null) {
      await _tokenStorage.clear();
      onSessionExpired?.call();
      return handler.next(err);
    }

    try {
      options
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
      // Enveloppe : {"statut": "success", "message": "...", "reponse": {"access": "...", "refresh": "..."}}
      final body = response.data;
      final tokens = body?['reponse'] is Map ? body!['reponse'] as Map : body;
      final access = tokens?['access'] as String?;
      if (access == null) return null;
      await _tokenStorage.saveTokens(access: access, refresh: tokens?['refresh'] as String?);
      return access;
    } on DioException {
      return null;
    }
  }
}
