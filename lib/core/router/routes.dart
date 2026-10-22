/// Chemins de navigation. Toujours passer par ces constantes (jamais de chaîne en dur).
/// Cartographie complète : claude.md §3.
abstract final class Routes {
  static const String splash = '/';

  // Authentification : e-mail → code reçu par e-mail → profil à compléter (nouveau compte)
  static const String login = '/connexion';
  static const String otp = '/connexion/code';
  static const String completeProfile = '/completer-profil';

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

  /// Choix d'un lieu ; `champ` = `depart` | `arrivee` | `carrefour`. Renvoie un `GeoPlace` via `pop`.
  static String placePicker(String champ) => '$home/$placePickerSegment?champ=$champ';

  /// Choix d'un point sur la carte. Renvoie un `GeoPlace` via `pop`.
  static const String mapPicker = '$home/$placePickerSegment/$mapPickerSegment';

  /// Détail d'un trajet (maquette « Détails & Réservation »). Depuis la recherche : point de
  /// prise en charge proposé (`pt`) et destination du passager (`alib`, `alat`, `alng`).
  static String tripDetail(String id, {String? pickupId, ({String libelle, double lat, double lng})? arrivee}) =>
      Uri(path: '$home/trajets/$id', queryParameters: {
        'pt': ?pickupId,
        if (arrivee != null) ...{'alib': arrivee.libelle, 'alat': '${arrivee.lat}', 'alng': '${arrivee.lng}'},
      }).toString();

  // Réservations (S4), sous l'onglet Mes trajets
  static const String bookingSegment = 'reservations/:id';

  /// Suivi d'une réservation (maquette « Suivi du trajet & Code de départ »), plein écran.
  static String booking(String id) => '$myTrips/reservations/$id';

  // Espace conducteur (S5), sous l'onglet Mes trajets
  static const String driverTripSegment = 'publies/:id';

  /// Gestion d'un trajet publié : demandes, code de départ, absence, fin du trajet. Plein écran.
  static String driverTrip(String id) => '$myTrips/publies/$id';

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

  // Portefeuille (recharge Flooz / Mixx via PayGate), plein écran
  static const String wallet = '/portefeuille';
  static const String walletRechargePath = '/portefeuille/recharger';
  static const String walletWithdraw = '/portefeuille/retirer';

  /// Recharge, avec un montant proposé (ex. complément avant une réservation). Renvoie `true`
  /// (pop) une fois le portefeuille crédité.
  static String walletRecharge({int? montant}) =>
      montant == null ? walletRechargePath : '$walletRechargePath?montant=$montant';

  // Après le trajet (S6), plein écran
  /// Signaler un problème sur une réservation (passager ou conducteur).
  static String report(String bookingId, {required String otherName}) =>
      Uri(path: '/signaler/$bookingId', queryParameters: {'nom': otherName}).toString();
  static const String reportPattern = '/signaler/:id';

  /// Catalogue des composants (environnement dev uniquement).
  static const String componentCatalog = '/dev/composants';

  /// Accessibles sans être connecté.
  static const Set<String> publicAuth = {login, otp};
}
