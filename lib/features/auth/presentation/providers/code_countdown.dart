/// Compte à rebours avant de pouvoir redemander un code envoyé par e-mail.
class CodeCountdown {
  const CodeCountdown({this.sentAt, this.resendIn = Duration.zero});

  final DateTime? sentAt;

  /// `delai_renvoi_s` de la réponse `CODE_ENVOYE`.
  final Duration resendIn;

  Duration remaining(DateTime now) {
    if (sentAt == null) return Duration.zero;
    final left = sentAt!.add(resendIn).difference(now);
    return left.isNegative ? Duration.zero : left;
  }
}
