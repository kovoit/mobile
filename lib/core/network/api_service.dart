import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_exception.dart';
import 'dio_client.dart';

/// Désérialise le contenu de `reponse` (objet, liste ou `null`).
typedef JsonParser<T> = T Function(Object? json);

/// Réponse réussie du backend : `{"statut": "success", "message": "...", "reponse": ...}`.
class ApiResponse<T> {
  const ApiResponse({required this.data, required this.message});

  final T data;

  /// Message destiné à l'utilisateur (ex. « Annulation tardive : elle compte dans votre taux de fiabilité. »).
  final String message;
}

/// Page d'une liste paginée : `reponse = {"count", "next", "previous", "results"}`.
class Paginated<T> {
  const Paginated({required this.count, required this.results, this.next, this.previous});

  final int count;
  final List<T> results;
  final String? next;
  final String? previous;

  bool get hasNext => next != null;
}

/// Fichier à envoyer en multipart (pièce KYC, photo de profil ou de véhicule).
/// [path] pointe vers un fichier temporaire : l'appelant le supprime après l'envoi.
class UploadFile {
  const UploadFile({required this.field, required this.path, this.filename});

  final String field;
  final String path;
  final String? filename;
}

/// Point d'entrée unique vers le backend Kovoit.
///
/// - Le JWT, le rafraîchissement et la déconnexion forcée sont gérés par [AuthInterceptor] (via [dioProvider]).
/// - Chaque méthode déballe l'enveloppe et renvoie le contenu de `reponse` désérialisé.
/// - Toute erreur (réseau, HTTP, `statut: failed`) est levée en [ApiException] typée.
class ApiService {
  const ApiService(this._dio);

  final Dio _dio;

  Future<T> get<T>(String path, {Map<String, dynamic>? query, required JsonParser<T> parse}) async =>
      (await send(path, method: 'GET', query: query, parse: parse)).data;

  Future<T> post<T>(String path, {Object? body, required JsonParser<T> parse}) async =>
      (await send(path, method: 'POST', body: body, parse: parse)).data;

  Future<T> patch<T>(String path, {Object? body, required JsonParser<T> parse}) async =>
      (await send(path, method: 'PATCH', body: body, parse: parse)).data;

  Future<void> delete(String path) => send<void>(path, method: 'DELETE', parse: (_) {});

  /// Liste paginée (`?page=` et `?taille=` côté backend, 20 éléments par défaut).
  Future<Paginated<T>> getPage<T>(
    String path, {
    Map<String, dynamic>? query,
    int? page,
    int? pageSize,
    required T Function(Map<String, dynamic> json) item,
  }) {
    return get(
      path,
      query: {...?query, 'page': ?page, 'taille': ?pageSize},
      parse: (json) {
        final map = asMap(json);
        return Paginated(
          count: map['count'] as int? ?? 0,
          next: map['next'] as String?,
          previous: map['previous'] as String?,
          results: asList(map['results']).map((e) => item(asMap(e))).toList(),
        );
      },
    );
  }

  /// Envoi multipart (`PATCH /moi/` avec photo, `POST /kyc/<type>/pieces/`…).
  Future<T> upload<T>(
    String path, {
    String method = 'POST',
    Map<String, Object?> fields = const {},
    required List<UploadFile> files,
    required JsonParser<T> parse,
  }) async {
    final form = FormData.fromMap({
      for (final entry in fields.entries)
        if (entry.value != null) entry.key: entry.value.toString(),
    });
    for (final file in files) {
      form.files.add(MapEntry(file.field, await MultipartFile.fromFile(file.path, filename: file.filename)));
    }
    return (await send(path, method: method, body: form, parse: parse)).data;
  }

  /// Variante complète : renvoie aussi le `message` du backend.
  Future<ApiResponse<T>> send<T>(
    String path, {
    required String method,
    Object? body,
    Map<String, dynamic>? query,
    required JsonParser<T> parse,
  }) async {
    final Response<dynamic> response;
    try {
      response = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: query,
        options: Options(method: method),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
    return _unwrap(response, parse);
  }

  ApiResponse<T> _unwrap<T>(Response<dynamic> response, JsonParser<T> parse) {
    final body = response.data;
    // 204 sans corps (suppression) : rien à déballer.
    if (body == null || body == '') return ApiResponse(data: parse(null), message: '');
    if (body is! Map || !body.containsKey('statut')) {
      throw const UnknownApiException('Réponse inattendue du serveur.');
    }
    if (body['statut'] != 'success') {
      throw ApiException.fromResponse(response.statusCode ?? 0, body);
    }
    try {
      return ApiResponse(data: parse(body['reponse']), message: body['message'] as String? ?? '');
    } on ApiException {
      rethrow;
    } catch (_) {
      // Contrat rompu (champ manquant ou mal typé) : erreur lisible plutôt qu'un TypeError.
      throw const UnknownApiException('Réponse du serveur illisible.');
    }
  }

  /// Aides de désérialisation pour les `parse`.
  static Map<String, dynamic> asMap(Object? json) => Map<String, dynamic>.from(json! as Map);

  static List<dynamic> asList(Object? json) => json as List<dynamic>? ?? const [];
}

final apiServiceProvider = Provider<ApiService>((ref) => ApiService(ref.watch(dioProvider)));
