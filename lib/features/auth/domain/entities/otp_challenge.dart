/// Code à 6 chiffres envoyé par e-mail (vérification de l'adresse ou mot de passe oublié).
/// Réponse `CODE_ENVOYE` du backend : `{"email", "delai_renvoi_s"}`.
class OtpChallenge {
  const OtpChallenge({required this.email, required this.resendIn});

  /// Délai de renvoi supposé quand le serveur ne le donne pas (403 `EMAIL_NON_VERIFIE`) :
  /// valeur par défaut du paramètre `otp_delai_renvoi_s`.
  static const Duration defaultResendIn = Duration(seconds: 60);

  /// Adresse à laquelle le code a été envoyé (normalisée).
  final String email;

  /// Délai avant de pouvoir redemander un code (`delai_renvoi_s`).
  final Duration resendIn;
}
