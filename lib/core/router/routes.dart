/// Chemins de navigation. Toujours passer par ces constantes (jamais de chaîne en dur).
abstract final class Routes {
  static const String splash = '/';

  // Onglets de la barre du bas
  static const String search = '/rechercher';
  static const String myTrips = '/mes-trajets';
  static const String profile = '/profil';

  /// Catalogue des composants (environnement dev uniquement).
  static const String componentCatalog = '/dev/composants';
}
