/// Données du mode démo (API simulée, `Env.useMockApi`). Jamais utilisées avec le vrai backend.
abstract final class DemoAccount {
  static const String email = 'demo@kovoit.tg';
  static const String password = 'kovoit123';

  /// Code OTP SMS accepté par l'API simulée.
  static const String otpCode = '123456';
}
