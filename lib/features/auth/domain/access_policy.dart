import 'entities/app_user.dart';

/// Raison pour laquelle une action est refusée. Sert à afficher le bon message et le bon bouton.
enum AccessDenial {
  suspended,
  kycPassagerMissing,
  kycPassagerPending,
  kycPassagerRejected,
  kycConducteurMissing,
  kycConducteurPending,
  kycConducteurRejected,
  vehicleMissing,
}

/// Droits d'accès (claude.md §3, retour UX du 08/10).
///
/// L'inscription ne bloque plus sur le KYC : l'utilisateur entre dans l'application,
/// mais réserver / publier / passer en mode conducteur restent soumis au KYC.
/// Le backend refait ces contrôles (403) ; ces fonctions servent à l'UX.
/// Chaque fonction renvoie `null` si l'action est autorisée, sinon la première raison bloquante.
abstract final class AccessPolicy {
  /// Réserver une place : KYC passager validé, compte actif.
  static AccessDenial? canBook(AppUser user) {
    if (user.isSuspended) return AccessDenial.suspended;
    return _passagerDenial(user.kycPassager);
  }

  /// Passer en mode conducteur : KYC passager + KYC conducteur validés, véhicule déclaré.
  static AccessDenial? canSwitchToDriver(AppUser user) {
    if (user.isSuspended) return AccessDenial.suspended;
    return _passagerDenial(user.kycPassager) ??
        _conducteurDenial(user.kycConducteur) ??
        (user.vehiculeDeclare ? null : AccessDenial.vehicleMissing);
  }

  /// Publier un trajet : mêmes droits que le mode conducteur, et être en mode conducteur.
  static AccessDenial? canPublish(AppUser user) => canSwitchToDriver(user);

  /// Le dossier conducteur ne peut être constitué qu'après l'envoi du dossier passager
  /// (les pièces d'identité du passager en font partie, spéc. §KYC).
  static bool canStartDriverKyc(AppUser user) =>
      user.kycPassager == KycStatus.enAttente || user.kycPassager == KycStatus.verifie;

  /// Macaron orange du Profil : une action KYC est attendue de l'utilisateur.
  static bool needsKycAttention(AppUser user) =>
      user.kycPassager == KycStatus.nonVerifie || user.kycPassager == KycStatus.rejete;

  static AccessDenial? _passagerDenial(KycStatus status) => switch (status) {
        KycStatus.verifie => null,
        KycStatus.enAttente => AccessDenial.kycPassagerPending,
        KycStatus.rejete => AccessDenial.kycPassagerRejected,
        KycStatus.nonVerifie => AccessDenial.kycPassagerMissing,
      };

  static AccessDenial? _conducteurDenial(KycStatus status) => switch (status) {
        KycStatus.verifie => null,
        KycStatus.enAttente => AccessDenial.kycConducteurPending,
        KycStatus.rejete => AccessDenial.kycConducteurRejected,
        KycStatus.nonVerifie => AccessDenial.kycConducteurMissing,
      };
}
