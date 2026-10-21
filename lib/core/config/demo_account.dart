/// Données du mode démo (API simulée, `Env.useMockApi`). Jamais utilisées avec le vrai backend.
abstract final class DemoAccount {
  /// Passager de démo : KYC passager validé.
  static const String email = 'demo@kovoit.tg';
  /// Code de connexion (e-mail) accepté par l'API simulée.
  static const String otpCode = '123456';

  /// Conducteur de démo : KYC validés, véhicule déclaré, mode conducteur.
  static const String driverEmail = 'conducteur@kovoit.tg';

  /// Code de départ des passagers fictifs qui demandent une place au conducteur de démo.
  static const String fakePassengerCode = '4821';
}
