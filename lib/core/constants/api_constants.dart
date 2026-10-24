/// URL du backend et chemins de l'API Kovoit (Django, préfixe `/api/v1`).
///
/// Changer de serveur sans toucher au code :
/// ```bash
/// flutter run --dart-define=USE_MOCK_API=false --dart-define=API_BASE_URL=http://192.168.1.20:8000/api/v1
/// flutter run --dart-define=USE_MOCK_API=false --dart-define=API_BASE_URL=https://xxxx.ngrok-free.app/api/v1
/// ```
/// Sans `API_BASE_URL`, l'URL dépend de `ENV` (voir [ApiConstants.baseUrlFor]).
abstract final class ApiConstants {
  static const String _override = String.fromEnvironment('API_BASE_URL');

  /// Émulateur Android : 10.0.2.2 = localhost de la machine hôte (`python manage.py runserver 0.0.0.0:8000`).
  static const String emulatorBaseUrl = 'http://10.0.2.2:8000/api/v1';
  static const String stagingBaseUrl = 'https://staging-api.kovoittg.com/api/v1';
  static const String prodBaseUrl = 'https://api.kovoittg.com/api/v1';

  /// URL retenue : `API_BASE_URL` si fourni, sinon celle de l'environnement.
  static String baseUrlFor({required bool isProd, required bool isStaging}) {
    if (_override.isNotEmpty) return _override;
    if (isProd) return prodBaseUrl;
    if (isStaging) return stagingBaseUrl;
    return emulatorBaseUrl;
  }

  /// En-tête évitant la page d'avertissement d'ngrok sur les appels API.
  static const Map<String, String> defaultHeaders = {
    'Accept': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };
}

/// Chemins relatifs à `baseUrl`. Les identifiants sont des UUID (chaînes).
abstract final class ApiEndpoints {
  // Santé
  static const sante = '/sante/';

  // Authentification sans mot de passe : code à 6 chiffres envoyé par e-mail
  static const otpDemander = '/auth/otp/demander/';
  static const otpVerifier = '/auth/otp/verifier/';
  static const jetonRafraichir = '/auth/jeton/rafraichir/';
  static const deconnexion = '/auth/deconnexion/';

  // Profil
  static const moi = '/moi/';
  static const moiMode = '/moi/mode/';
  static const moiEconomies = '/moi/economies/';
  static String profilPublic(String userId) => '/utilisateurs/$userId/';

  // KYC (type = passager | conducteur)
  static const kyc = '/kyc/';
  static String kycPieces(String type) => '/kyc/$type/pieces/';
  static String kycSoumettre(String type) => '/kyc/$type/soumettre/';

  // Véhicules
  static const vehicules = '/vehicules/';
  static String vehicule(String id) => '/vehicules/$id/';

  // Lieux connus de Lomé (saisie du départ et de l'arrivée)
  static const lieux = '/lieux/';

  // Trajets
  static const trajets = '/trajets/';
  static const trajetsRecherche = '/trajets/recherche/';
  static const trajetsEstimation = '/trajets/estimation/';
  static const notifications = '/notifications/';
  static const notificationsNonLues = '/notifications/non-lues/';
  static const notificationsToutLire = '/notifications/tout-lire/';
  static String notificationLue(String id) => '/notifications/$id/lue/';
  static const mesTrajets = '/trajets/mes-trajets/';
  static String trajet(String id) => '/trajets/$id/';
  static String trajetPosition(String id) => '/trajets/$id/position/';
  static String trajetTerminer(String id) => '/trajets/$id/terminer/';
  static String trajetAnnuler(String id) => '/trajets/$id/annuler/';
  static String trajetReservations(String id) => '/trajets/$id/reservations/';

  // Réservations
  static const reservations = '/reservations/';
  static String reservation(String id) => '/reservations/$id/';
  static String reservationAccepter(String id) => '/reservations/$id/accepter/';
  static String reservationRefuser(String id) => '/reservations/$id/refuser/';
  static String reservationAnnuler(String id) => '/reservations/$id/annuler/';
  static String reservationCodeDepart(String id) => '/reservations/$id/code-depart/';
  static String reservationAbsent(String id) => '/reservations/$id/absent/';
  static String reservationConfirmerArrivee(String id) => '/reservations/$id/confirmer-arrivee/';
  static String reservationNote(String id) => '/reservations/$id/note/';
  static String reservationSignalement(String id) => '/reservations/$id/signalement/';
  static String reservationPartage(String id) => '/reservations/$id/partage/';

  // Portefeuille : recharge et retrait par Flooz / Mixx (PayGate)
  static const portefeuille = '/portefeuille/';
  static const portefeuilleMoyens = '/portefeuille/moyens/';
  static const portefeuilleTransactions = '/portefeuille/transactions/';
  static String portefeuilleTransaction(String id) => '/portefeuille/transactions/$id/';
  static const portefeuilleRecharger = '/portefeuille/recharger/';
  static const portefeuilleRetirer = '/portefeuille/retirer/';

  // Notifications push
  static const appareils = '/notifications/appareils/';
  static String appareil(String jeton) => '/notifications/appareils/$jeton/';

  /// Requêtes qui ne doivent jamais déclencher un rafraîchissement du jeton.
  static const sansRafraichissement = {otpDemander, otpVerifier, jetonRafraichir};
}
