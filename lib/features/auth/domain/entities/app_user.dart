/// Statut d'un dossier KYC (valeurs API : non_verifie, en_attente, verifie, rejete).
enum KycStatus {
  nonVerifie('non_verifie'),
  enAttente('en_attente'),
  verifie('verifie'),
  rejete('rejete');

  const KycStatus(this.apiValue);

  final String apiValue;

  static KycStatus fromApi(String? value) =>
      values.firstWhere((s) => s.apiValue == value, orElse: () => KycStatus.nonVerifie);
}

enum AccountStatus {
  actif('actif'),
  suspendu('suspendu');

  const AccountStatus(this.apiValue);

  final String apiValue;

  static AccountStatus fromApi(String? value) =>
      values.firstWhere((s) => s.apiValue == value, orElse: () => AccountStatus.actif);
}

enum UserMode {
  passager('passager'),
  conducteur('conducteur');

  const UserMode(this.apiValue);

  final String apiValue;

  static UserMode fromApi(String? value) =>
      values.firstWhere((m) => m.apiValue == value, orElse: () => UserMode.passager);
}

/// Utilisateur connecté, tel que renvoyé par l'API (`/auth/me/`).
/// Les droits (réserver, publier) se déduisent de ces statuts, mais le backend fait foi.
class AppUser {
  const AppUser({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.email,
    this.telephone,
    this.telephoneVerifie = false,
    this.photoUrl,
    this.modeActif = UserMode.passager,
    this.statutCompte = AccountStatus.actif,
    this.suspenduJusquAu,
    this.kycPassager = KycStatus.nonVerifie,
    this.kycConducteur = KycStatus.nonVerifie,
  });

  final int id;
  final String prenom;
  final String nom;
  final String email;

  /// `null` pour un compte créé via Google qui n'a pas encore saisi son numéro.
  final String? telephone;
  final bool telephoneVerifie;
  final String? photoUrl;
  final UserMode modeActif;
  final AccountStatus statutCompte;
  final DateTime? suspenduJusquAu;
  final KycStatus kycPassager;
  final KycStatus kycConducteur;

  String get nomComplet => '$prenom $nom'.trim();

  bool get hasTelephone => telephone != null && telephone!.isNotEmpty;

  bool get isSuspended => statutCompte == AccountStatus.suspendu;

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.id == id &&
      other.prenom == prenom &&
      other.nom == nom &&
      other.email == email &&
      other.telephone == telephone &&
      other.telephoneVerifie == telephoneVerifie &&
      other.photoUrl == photoUrl &&
      other.modeActif == modeActif &&
      other.statutCompte == statutCompte &&
      other.suspenduJusquAu == suspenduJusquAu &&
      other.kycPassager == kycPassager &&
      other.kycConducteur == kycConducteur;

  @override
  int get hashCode => Object.hash(
        id,
        prenom,
        nom,
        email,
        telephone,
        telephoneVerifie,
        photoUrl,
        modeActif,
        statutCompte,
        suspenduJusquAu,
        kycPassager,
        kycConducteur,
      );
}
