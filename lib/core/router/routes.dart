/// Chemins de navigation. Toujours passer par ces constantes (jamais de chaîne en dur).
/// Cartographie complète : claude.md §3.
abstract final class Routes {
  static const String splash = '/';

  // Authentification (S1)
  static const String login = '/connexion';
  static const String register = '/inscription';
  static const String forgotPassword = '/mot-de-passe-oublie';
  static const String phone = '/telephone';
  static const String otp = '/verification-sms';

  // Onglets de la barre du bas
  /// Tableau de bord selon le mode : Rechercher (passager) ou Espace conducteur (conducteur).
  static const String home = '/accueil';
  static const String myTrips = '/mes-trajets';
  static const String profile = '/profil';

  // Recherche (S3), sous l'onglet Accueil
  static const String searchResultsSegment = 'resultats';
  static const String placePickerSegment = 'lieu';
  static const String mapPickerSegment = 'carte';
  static const String tripDetailSegment = 'trajets/:id';

  /// Résultats : critères dans les paramètres d'URL (`SearchQuery.toQueryParameters`).
  static const String searchResults = '$home/$searchResultsSegment';

  /// Choix d'un lieu ; `champ` = `depart` | `arrivee`. Renvoie un `GeoPlace` via `pop`.
  static String placePicker(String champ) => '$home/$placePickerSegment?champ=$champ';

  /// Choix d'un point sur la carte. Renvoie un `GeoPlace` via `pop`.
  static const String mapPicker = '$home/$placePickerSegment/$mapPickerSegment';

  /// Détail d'un trajet (maquette « Détails & Réservation »).
  static String tripDetail(int id, {int places = 1}) => '$home/trajets/$id?places=$places';

  // Sous-écrans du Profil (S2), plein écran sans barre du bas
  static const String kycSegment = 'verification/:type';
  static const String kycSubmittedSegment = 'envoye';
  static const String vehicleSegment = 'vehicule';
  static const String becomeDriverSegment = 'devenir-conducteur';

  /// `/profil/verification/passager` ou `/profil/verification/conducteur`.
  static String kyc(String type) => '$profile/verification/$type';

  /// Récapitulatif après envoi (maquette « Profil vérifié »).
  static String kycSubmitted(String type) => '${kyc(type)}/$kycSubmittedSegment';

  static const String vehicle = '$profile/$vehicleSegment';
  static const String becomeDriver = '$profile/$becomeDriverSegment';

  /// Catalogue des composants (environnement dev uniquement).
  static const String componentCatalog = '/dev/composants';

  /// Accessibles sans être connecté.
  static const Set<String> publicAuth = {login, register, forgotPassword};

  /// Étapes de vérification du téléphone.
  static const Set<String> phoneVerification = {phone, otp};
}
