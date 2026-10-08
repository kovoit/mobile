/// Résultat d'un envoi de code OTP SMS.
class OtpChallenge {
  const OtpChallenge({required this.telephone, required this.resendIn, required this.expiresIn});

  /// Numéro auquel le SMS a été envoyé (format E.164).
  final String telephone;

  /// Délai avant de pouvoir redemander un code.
  final Duration resendIn;

  /// Durée de validité du code.
  final Duration expiresIn;
}
