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
