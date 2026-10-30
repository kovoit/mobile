/// Données saisies à l'inscription (`POST /auth/inscription/`).
///
/// Envoyée telle quelle puis oubliée : jamais persistée, jamais gardée dans un état Riverpod
/// (le mot de passe ne vit que dans le `TextEditingController` de l'écran et dans la requête).
class Registration {
  const Registration({
    required this.prenom,
    required this.nom,
    required this.email,
    required this.telephone,
    required this.motDePasse,
    required this.cguAcceptees,
  });

  final String prenom;
  final String nom;
  final String email;

  /// Format `+228XXXXXXXX` (`Validators.normalizeTogoPhone`). Le backend reste juge.
  final String telephone;
  final String motDePasse;
  final bool cguAcceptees;

  /// Jamais le mot de passe dans un journal ou un message d'erreur.
  @override
  String toString() => 'Registration($email)';
}
