/// Environnement d'exécution, choisi au build :
/// `flutter run --dart-define=ENV=dev` (défaut), `staging` ou `prod`.
/// L'URL de l'API peut être surchargée avec `--dart-define=API_BASE_URL=...`.
enum AppEnv { dev, staging, prod }

abstract final class Env {
  static const String _envName = String.fromEnvironment('ENV', defaultValue: 'dev');
  static const String _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

  static AppEnv get current => AppEnv.values.firstWhere(
        (e) => e.name == _envName,
        orElse: () => AppEnv.dev,
      );

  static bool get isDev => current == AppEnv.dev;

  static const String _useMockApi = String.fromEnvironment('USE_MOCK_API');

  /// Fausse API en mémoire tant que le backend n'est pas disponible.
  /// Activée par défaut en dev (`--dart-define=USE_MOCK_API=false` pour viser le vrai backend),
  /// jamais en production.
  static bool get useMockApi {
    if (current == AppEnv.prod) return false;
    if (_useMockApi.isEmpty) return isDev;
    return _useMockApi == 'true';
  }

  /// Client OAuth « Web » Google (audience de l'ID token vérifié par le backend).
  /// `--dart-define=GOOGLE_SERVER_CLIENT_ID=xxx.apps.googleusercontent.com`
  static const String googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
    return switch (current) {
      // 10.0.2.2 = localhost de la machine hôte vu depuis l'émulateur Android.
      AppEnv.dev => 'http://10.0.2.2:8000/api/v1',
      AppEnv.staging => 'https://staging-api.kovoit.tg/api/v1',
      AppEnv.prod => 'https://api.kovoit.tg/api/v1',
    };
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
