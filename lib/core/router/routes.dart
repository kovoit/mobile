/// Chemins de navigation. Toujours passer par ces constantes (jamais de chaîne en dur).
abstract final class Routes {
  static const String splash = '/';

  // Authentification (S1)
  static const String login = '/connexion';
  static const String register = '/inscription';
  static const String forgotPassword = '/mot-de-passe-oublie';
  static const String phone = '/telephone';
  static const String otp = '/verification-sms';

  // Onglets de la barre du bas
  static const String search = '/rechercher';
  static const String myTrips = '/mes-trajets';
  static const String profile = '/profil';

  /// Catalogue des composants (environnement dev uniquement).
  static const String componentCatalog = '/dev/composants';

  /// Accessibles sans être connecté.
  static const Set<String> publicAuth = {login, register, forgotPassword};

  /// Étapes de vérification du téléphone.
  static const Set<String> phoneVerification = {phone, otp};
}
