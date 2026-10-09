import '../entities/app_user.dart';
import '../entities/otp_challenge.dart';

/// Contrat d'authentification (décision D3 : email + mot de passe ou Google, puis OTP SMS).
/// Les erreurs remontent en `ApiException` (voir core/network).
abstract interface class AuthRepository {
  /// Restaure la session depuis les jetons stockés. `null` si aucune session valide.
  Future<AppUser?> restoreSession();

  Future<AppUser> login({required String email, required String password});

  Future<AppUser> register({
    required String nomComplet,
    required String email,
    required String telephone,
    required String password,
  });

  /// `null` si l'utilisateur a annulé la fenêtre Google.
  Future<AppUser?> signInWithGoogle();

  Future<AppUser> updatePhone(String telephone);

  /// Relit l'utilisateur (après un envoi KYC, une déclaration de véhicule…).
  Future<AppUser> refreshUser();

  /// Bascule passager ↔ conducteur. Lève `ForbiddenApiException` si le mode conducteur est refusé.
  Future<AppUser> updateMode(UserMode mode);

  Future<OtpChallenge> sendOtp();

  Future<AppUser> verifyOtp(String code);

  Future<void> requestPasswordReset(String email);

  Future<void> logout();
}

/// Levée quand Google Sign-In n'est pas configuré (client OAuth manquant).
class GoogleSignInUnavailableException implements Exception {
  const GoogleSignInUnavailableException([this.message = 'La connexion Google n’est pas encore disponible.']);

  final String message;

  @override
  String toString() => message;
}
