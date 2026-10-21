import 'package:dio/dio.dart';

/// Erreur API typée, convertie depuis [DioException].
/// Les écrans affichent [message] ; les formulaires utilisent [fieldErrors] ;
/// la logique d'écran peut tester [code] (code métier du backend, ex. `PLUS_DE_PLACE`).
///
/// Format d'erreur du backend :
/// `{"statut": "failed", "message": "...", "reponse": {"code": "...", "erreurs": {...}}}`.
sealed class ApiException implements Exception {
  const ApiException(this.message, {this.code, this.details = const {}});

  final String message;

  /// Code métier stable (`reponse.code`), `null` hors réponse du backend (réseau, délai…).
  final String? code;

  /// Contenu brut de `reponse.erreurs` (ex. `pieces_manquantes` pour un dossier KYC incomplet).
  final Map<String, dynamic> details;

  factory ApiException.fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const TimeoutApiException();
      case DioExceptionType.connectionError:
        return const NetworkApiException();
      case DioExceptionType.cancel:
        return const UnknownApiException('Requête annulée.');
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        if (error.error is ApiException) return error.error! as ApiException;
        return const UnknownApiException('Une erreur inattendue est survenue.');
      case DioExceptionType.badResponse:
        return fromResponse(error.response?.statusCode ?? 0, error.response?.data);
    }
  }

  /// Construit l'exception à partir du statut HTTP et du corps (enveloppe Kovoit ou format DRF brut).
  static ApiException fromResponse(int status, dynamic data) {
    final message = _extractMessage(data);
    final code = _extractCode(data);
    final details = _extractDetails(data);

    return switch (status) {
      400 => BadRequestApiException(
          message ?? 'Données invalides.',
          code: code,
          details: details,
          fieldErrors: _fieldErrors(details),
        ),
      401 => UnauthorizedApiException(message ?? 'Session expirée, veuillez vous reconnecter.', code: code),
      403 => ForbiddenApiException(message ?? "Vous n'avez pas les droits pour cette action.", code: code),
      404 => NotFoundApiException(message ?? 'Ressource introuvable.', code: code),
      409 => ConflictApiException(
          message ?? 'Action impossible : la situation a changé, veuillez réessayer.',
          code: code,
          details: details,
        ),
      429 => TooManyAttemptsApiException(message ?? 'Trop de tentatives. Réessayez plus tard.', code: code),
      >= 500 => const ServerApiException(),
      _ => UnknownApiException(message ?? 'Une erreur inattendue est survenue.', code: code),
    };
  }

  static bool _isEnvelope(dynamic data) => data is Map && data.containsKey('statut');

  static String? _extractMessage(dynamic data) {
    if (data is! Map) return null;
    if (_isEnvelope(data)) {
      final message = data['message'];
      return message is String && message.isNotEmpty ? message : null;
    }
    // Format DRF brut : {"detail": "..."} ou {"non_field_errors": ["..."]}
    final detail = data['detail'];
    if (detail is String) return detail;
    final nonField = data['non_field_errors'];
    if (nonField is List && nonField.isNotEmpty) return nonField.first.toString();
    return null;
  }

  static String? _extractCode(dynamic data) {
    if (!_isEnvelope(data)) return null;
    final reponse = data['reponse'];
    final code = reponse is Map ? reponse['code'] : null;
    return code is String ? code : null;
  }

  static Map<String, dynamic> _extractDetails(dynamic data) {
    if (data is! Map) return const {};
    final source = _isEnvelope(data) ? (data['reponse'] is Map ? data['reponse']['erreurs'] : null) : data;
    if (source is! Map) return const {};
    return source.map((key, value) => MapEntry(key.toString(), value));
  }

  /// `{"telephone": ["Ce numéro existe déjà."]}` → `{"telephone": "Ce numéro existe déjà."}`.
  static Map<String, String> _fieldErrors(Map<String, dynamic> details) {
    final errors = <String, String>{};
    details.forEach((key, value) {
      if (key == 'detail' || key == 'non_field_errors') return;
      if (value is List && value.isNotEmpty) {
        errors[key] = value.first.toString();
      } else if (value is String) {
        errors[key] = value;
      }
    });
    return errors;
  }

  @override
  String toString() => '$runtimeType(${code ?? '-'}): $message';
}

final class NetworkApiException extends ApiException {
  const NetworkApiException() : super('Pas de connexion internet. Vérifiez votre réseau.');
}

final class TimeoutApiException extends ApiException {
  const TimeoutApiException() : super('Le serveur met trop de temps à répondre. Réessayez.');
}

final class BadRequestApiException extends ApiException {
  const BadRequestApiException(super.message, {this.fieldErrors = const {}, super.code, super.details});

  final Map<String, String> fieldErrors;
}

final class UnauthorizedApiException extends ApiException {
  const UnauthorizedApiException(super.message, {super.code});
}

final class ForbiddenApiException extends ApiException {
  const ForbiddenApiException(super.message, {super.code});
}

final class NotFoundApiException extends ApiException {
  const NotFoundApiException(super.message, {super.code});
}

/// 409 : typiquement plus de place disponible ou statut déjà modifié.
final class ConflictApiException extends ApiException {
  const ConflictApiException(super.message, {super.code, super.details});
}

/// 429 : trop d'essais (code de départ, renvoi d'OTP…).
final class TooManyAttemptsApiException extends ApiException {
  const TooManyAttemptsApiException(super.message, {super.code});
}

final class ServerApiException extends ApiException {
  const ServerApiException() : super('Le service est momentanément indisponible.');
}

final class UnknownApiException extends ApiException {
  const UnknownApiException(super.message, {super.code});
}
