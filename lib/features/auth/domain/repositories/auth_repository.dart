import '../entities/app_user.dart';
import '../entities/otp_challenge.dart';
import '../entities/registration.dart';

/// Contrat d'authentification (D-68) : inscription, vérification de l'e-mail par un code à
/// 6 chiffres, connexion par e-mail + mot de passe, mot de passe oublié par code.
/// Les erreurs remontent en `ApiException` (voir core/network) avec le message du backend.
/// Le mot de passe n'est jamais stocké : seuls les jetons le sont (`TokenStorage`).
abstract interface class AuthRepository {
  /// Restaure la session depuis les jetons stockés. `null` si aucune session valide.
  Future<AppUser?> restoreSession();

  /// Crée le compte et envoie le code de vérification ; aucun jeton.
  /// 400 `DONNEES_INVALIDES` / `TELEPHONE_INVALIDE` / `MOT_DE_PASSE_FAIBLE` (erreurs par champ),
  /// 409 `EMAIL_DEJA_UTILISE`.
  Future<OtpChallenge> register(Registration registration);

  /// Vérifie l'e-mail et ouvre la session (jetons stockés). 400 `CODE_OTP_INVALIDE`.
  Future<AppUser> verifyEmail({required String email, required String code});

  /// Renvoie le code de vérification. 429 `TROP_DE_REQUETES` à la limite.
  Future<OtpChallenge> resendVerificationCode(String email);

  /// Ouvre la session (jetons stockés). 401 `IDENTIFIANTS_INVALIDES` ; 403 `EMAIL_NON_VERIFIE`
  /// (bon mot de passe, adresse à vérifier : écran Vérification) ; 429 `TROP_DE_REQUETES`.
  Future<AppUser> login({required String email, required String password});

  /// Demande un code de réinitialisation (réponse identique que le compte existe ou non).
  Future<OtpChallenge> requestPasswordReset(String email);

  /// Fixe le nouveau mot de passe. Aucun jeton : retour à la Connexion.
  /// 400 `MOT_DE_PASSE_FAIBLE` (contrôlé avant le code) ou `CODE_OTP_INVALIDE`.
  Future<void> resetPassword({required String email, required String code, required String password});

  /// Compte ancien sans nom ou sans téléphone (D-80) : `PATCH /moi/` avec les CGU.
  /// Erreurs par champ dans `BadRequestApiException.fieldErrors`.
  /// Profil complété en acceptant les CGU (case cochée, obligatoire).
  Future<AppUser> completeProfile({required String prenom, required String nom, required String telephone});

  Future<AppUser> acceptTerms();

  /// Relit l'utilisateur (après un envoi KYC, une déclaration de véhicule…).
  Future<AppUser> refreshUser();

  /// Bascule passager ↔ conducteur. Lève `ForbiddenApiException` si le mode conducteur est refusé.
  Future<AppUser> updateMode(UserMode mode);

  /// Envoie la photo de profil (D-19) prise ou choisie à [path], puis renvoie le profil à jour.
  /// Le fichier temporaire est supprimé de l'appareil, que l'envoi réussisse ou non.
  /// Image refusée : `BadRequestApiException` (`DONNEES_INVALIDES`) avec `fieldErrors['photo']`.
  Future<AppUser> updatePhoto(String path);

  Future<void> logout();

  /// Supprime le compte puis efface la session locale.
  Future<void> deleteAccount(String confirmation);
}
