import '../entities/app_user.dart';
import '../entities/otp_challenge.dart';

/// Contrat d'authentification : connexion sans mot de passe, par un code à 6 chiffres reçu par e-mail.
/// Le compte est créé au premier code valide ; le profil (prénom, nom, téléphone) est complété ensuite.
/// Les erreurs remontent en `ApiException` (voir core/network).
abstract interface class AuthRepository {
  /// Restaure la session depuis les jetons stockés. `null` si aucune session valide.
  Future<AppUser?> restoreSession();

  /// Envoie un code à [email]. `TooManyAttemptsApiException` si un code vient d'être envoyé.
  Future<OtpChallenge> requestCode(String email);

  /// Ouvre la session. `BadRequestApiException` (code `CODE_OTP_INVALIDE`) si le code est faux ou expiré.
  Future<AppUser> verifyCode({required String email, required String code});

  /// Erreurs par champ dans `BadRequestApiException.fieldErrors`.
  /// Profil complété en acceptant les CGU (case cochée, obligatoire).
  Future<AppUser> completeProfile({required String prenom, required String nom, required String telephone});

  Future<AppUser> acceptTerms();

  /// Relit l'utilisateur (après un envoi KYC, une déclaration de véhicule…).
  Future<AppUser> refreshUser();

  /// Bascule passager ↔ conducteur. Lève `ForbiddenApiException` si le mode conducteur est refusé.
  Future<AppUser> updateMode(UserMode mode);

  Future<void> logout();

  /// Supprime le compte puis efface la session locale.
  Future<void> deleteAccount(String confirmation);
}
