import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/otp_challenge.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this._remote, required this._tokenStorage});

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokenStorage;

  /// Délai entre deux envois (paramètre backend `otp_delai_renvoi_s`, non renvoyé par l'API).
  static const resendDelay = Duration(seconds: 60);

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
  Future<OtpChallenge> requestCode(String email) async {
    final normalized = _normalize(email);
    await _remote.requestCode(normalized);
    return OtpChallenge(email: normalized, resendIn: resendDelay);
  }

  @override
  Future<AppUser> verifyCode({required String email, required String code}) async {
    final connexion = await _remote.verifyCode(email: _normalize(email), code: code);
    await _tokenStorage.saveTokens(access: connexion.access, refresh: connexion.refresh);
    return connexion.utilisateur.toEntity();
  }

  @override
  Future<AppUser> completeProfile({required String prenom, required String nom, required String telephone}) async =>
      (await _remote.updateProfile(prenom: prenom.trim(), nom: nom.trim(), telephone: telephone)).toEntity();

  @override
  Future<AppUser> refreshUser() async => (await _remote.me()).toEntity();

  @override
  Future<AppUser> updateMode(UserMode mode) async => (await _remote.updateMode(mode.apiValue)).toEntity();

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
