import '../../../../core/network/api_exception.dart';
import '../../../../core/services/photo_capture_service.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/otp_challenge.dart';
import '../../domain/entities/registration.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../dto/connexion_dto.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this._remote, required this._tokenStorage, required this._capture});

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokenStorage;

  /// Supprime la photo de profil temporaire après l'envoi.
  final PhotoCaptureService _capture;

  static String _normalize(String email) => email.trim().toLowerCase();

  @override
  Future<AppUser?> restoreSession() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null) return null;
    try {
      return (await _remote.me()).toEntity();
    } on UnauthorizedApiException {
      // Refresh déjà tenté par l'intercepteur : la session est perdue.
      await _tokenStorage.clear();
      return null;
    }
  }

  @override
  Future<OtpChallenge> register(Registration registration) async => (await _remote.register(
        prenom: registration.prenom.trim(),
        nom: registration.nom.trim(),
        email: _normalize(registration.email),
        telephone: registration.telephone,
        motDePasse: registration.motDePasse, // tel quel : aucun espace retiré
        cguAcceptees: registration.cguAcceptees,
      ))
          .toEntity();

  @override
  Future<AppUser> verifyEmail({required String email, required String code}) async =>
      _openSession(await _remote.verifyEmail(email: _normalize(email), code: code.trim()));

  @override
  Future<OtpChallenge> resendVerificationCode(String email) async =>
      (await _remote.resendVerificationCode(_normalize(email))).toEntity();

  @override
  Future<AppUser> login({required String email, required String password}) async =>
      _openSession(await _remote.login(email: _normalize(email), motDePasse: password));

  @override
  Future<OtpChallenge> requestPasswordReset(String email) async =>
      (await _remote.requestPasswordReset(_normalize(email))).toEntity();

  @override
  Future<void> resetPassword({required String email, required String code, required String password}) =>
      _remote.resetPassword(email: _normalize(email), code: code.trim(), motDePasse: password);

  /// Seuls les jetons sont conservés (stockage sécurisé), jamais le mot de passe.
  Future<AppUser> _openSession(ConnexionDto connexion) async {
    await _tokenStorage.saveTokens(access: connexion.access, refresh: connexion.refresh);
    return connexion.utilisateur.toEntity();
  }

  @override
  Future<AppUser> completeProfile({required String prenom, required String nom, required String telephone}) async =>
      (await _remote.updateProfile(prenom: prenom.trim(), nom: nom.trim(), telephone: telephone, acceptCgu: true))
          .toEntity();

  @override
  Future<AppUser> acceptTerms() async => (await _remote.acceptTerms()).toEntity();

  @override
  Future<AppUser> refreshUser() async => (await _remote.me()).toEntity();

  @override
  Future<AppUser> updateMode(UserMode mode) async => (await _remote.updateMode(mode.apiValue)).toEntity();

  @override
  Future<AppUser> updatePhoto(String path) async {
    try {
      return (await _remote.updatePhoto(path)).toEntity();
    } finally {
      // Succès ou échec : aucune copie de la photo ne reste sur l'appareil.
      await _capture.discard(path);
    }
  }

  @override
  Future<void> deleteAccount(String confirmation) async {
    await _remote.deleteAccount(confirmation);
    await _tokenStorage.clear(); // sessions déjà révoquées côté serveur
  }

  @override
  Future<void> logout() async {
    final refresh = await _tokenStorage.readRefreshToken();
    try {
      if (refresh != null) await _remote.logout(refresh);
    } on ApiException {
      // La déconnexion locale doit réussir même si l'API est injoignable.
    } finally {
      await _tokenStorage.clear();
    }
  }
}
