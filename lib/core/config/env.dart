import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';

/// Environnement d'exécution, choisi au build :
/// `flutter run --dart-define=ENV=dev` (défaut), `staging` ou `prod`.
/// L'URL de l'API peut être surchargée avec `--dart-define=API_BASE_URL=...`.
enum AppEnv { dev, staging, prod }

abstract final class Env {
  static const String _envName = String.fromEnvironment('ENV', defaultValue: 'dev');

  static AppEnv get current => AppEnv.values.firstWhere(
        (e) => e.name == _envName,
        orElse: () => AppEnv.dev,
      );

  static bool get isDev => current == AppEnv.dev;

  static const String _useMockApi = String.fromEnvironment('USE_MOCK_API');

  /// Fausse API en mémoire (démo hors ligne) : `--dart-define=USE_MOCK_API=true`, jamais en
  /// production. Par défaut, l'app vise le vrai backend (voir [apiBaseUrl]).
  static bool get useMockApi =>
      current != AppEnv.prod && (debugUseMockApiOverride ?? _useMockApi == 'true');

  /// Tests uniquement : force la fausse API (voir `test/flutter_test_config.dart`).
  @visibleForTesting
  static bool? debugUseMockApiOverride;

  /// Notifications push FCM : nécessitent un projet Firebase configuré (voir README).
  /// `--dart-define=PUSH_ENABLED=true`. Sans push, l'app relit les notifications périodiquement.
  static const bool pushEnabled = bool.fromEnvironment('PUSH_ENABLED');

  /// URL du backend : voir [ApiConstants] (surcharge `API_BASE_URL` pour un téléphone ou ngrok).
  static String get apiBaseUrl => ApiConstants.baseUrlFor(
        isProd: current == AppEnv.prod,
        isStaging: current == AppEnv.staging,
      );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
