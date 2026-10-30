/// Données du mode démo (API simulée, `Env.useMockApi`). Jamais utilisées avec le vrai backend.
abstract final class DemoAccount {
  /// Passager de démo : KYC passager validé.
  static const String email = 'demo@kovoit.tg';

  /// Mot de passe des comptes de démo (passager et conducteur) de l'API simulée.
  static const String password = 'Trajet-Lome-26';

  /// Code reçu « par e-mail » accepté par l'API simulée (vérification, mot de passe oublié).
  static const String otpCode = '123456';

  /// Compte ancien, créé par code et sans mot de passe (D-69) ni téléphone (D-80).
  static const String legacyEmail = 'ancien@kovoit.tg';

  /// Conducteur de démo : KYC validés, véhicule déclaré, mode conducteur.
  static const String driverEmail = 'conducteur@kovoit.tg';

  /// Code de départ des passagers fictifs qui demandent une place au conducteur de démo.
  static const String fakePassengerCode = '4821';
}
