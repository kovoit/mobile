import 'package:dio/dio.dart';

/// Erreur API typée, convertie depuis [DioException].
/// Les écrans affichent [message] ; les formulaires utilisent [fieldErrors].
sealed class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

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
        return UnknownApiException(
          error.error is ApiException ? (error.error! as ApiException).message : 'Une erreur inattendue est survenue.',
        );
      case DioExceptionType.badResponse:
        return _fromResponse(error.response);
    }
  }

  static ApiException _fromResponse(Response<dynamic>? response) {
    final status = response?.statusCode ?? 0;
    final data = response?.data;
    final detail = _extractDetail(data);

    return switch (status) {
      400 => BadRequestApiException(detail ?? 'Données invalides.', fieldErrors: _extractFieldErrors(data)),
      401 => UnauthorizedApiException(detail ?? 'Session expirée, veuillez vous reconnecter.'),
      403 => ForbiddenApiException(detail ?? "Vous n'avez pas les droits pour cette action."),
      404 => NotFoundApiException(detail ?? 'Ressource introuvable.'),
      409 => ConflictApiException(detail ?? 'Action impossible : la situation a changé, veuillez réessayer.'),
      >= 500 => const ServerApiException(),
      _ => UnknownApiException(detail ?? 'Une erreur inattendue est survenue.'),
    };
  }

  /// Format DRF : `{"detail": "..."}` ou `{"non_field_errors": ["..."]}`.
  static String? _extractDetail(dynamic data) {
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String) return detail;
      final nonField = data['non_field_errors'];
      if (nonField is List && nonField.isNotEmpty) return nonField.first.toString();
    }
    return null;
  }

  /// Format DRF : `{"telephone": ["Ce numéro existe déjà."]}`.
  static Map<String, String> _extractFieldErrors(dynamic data) {
    if (data is! Map) return const {};
    final errors = <String, String>{};
    data.forEach((key, value) {
      if (key == 'detail' || key == 'non_field_errors') return;
      if (value is List && value.isNotEmpty) {
        errors[key.toString()] = value.first.toString();
      } else if (value is String) {
        errors[key.toString()] = value;
      }
    });
    return errors;
  }

  @override
  String toString() => '$runtimeType: $message';
}

final class NetworkApiException extends ApiException {
  const NetworkApiException() : super('Pas de connexion internet. Vérifiez votre réseau.');
}

final class TimeoutApiException extends ApiException {
  const TimeoutApiException() : super('Le serveur met trop de temps à répondre. Réessayez.');
}

final class BadRequestApiException extends ApiException {
  const BadRequestApiException(super.message, {this.fieldErrors = const {}});

  final Map<String, String> fieldErrors;
}

final class UnauthorizedApiException extends ApiException {
  const UnauthorizedApiException(super.message);
}

final class ForbiddenApiException extends ApiException {
  const ForbiddenApiException(super.message);
}

final class NotFoundApiException extends ApiException {
  const NotFoundApiException(super.message);
}

/// 409 : typiquement plus de place disponible ou statut déjà modifié.
final class ConflictApiException extends ApiException {
  const ConflictApiException(super.message);
}

final class ServerApiException extends ApiException {
  const ServerApiException() : super('Le service est momentanément indisponible.');
}

final class UnknownApiException extends ApiException {
  const UnknownApiException(super.message);
}
