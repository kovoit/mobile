/// Code de connexion envoyé par e-mail.
class OtpChallenge {
  const OtpChallenge({required this.email, required this.resendIn});

  /// Adresse à laquelle le code a été envoyé (normalisée).
  final String email;

  /// Délai avant de pouvoir redemander un code.
  final Duration resendIn;
}
