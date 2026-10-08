import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/otp_challenge.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../dto/auth_response_dto.dart';
import '../services/google_auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this._remote,
    required this._tokenStorage,
    required this._google,
  });

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokenStorage;
  final GoogleAuthService _google;

  Future<AppUser> _openSession(AuthResponseDto response) async {
    await _tokenStorage.saveTokens(access: response.access, refresh: response.refresh);
    return response.user.toEntity();
  }

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
  Future<AppUser> login({required String email, required String password}) async =>
      _openSession(await _remote.login(email: email.trim().toLowerCase(), password: password));

  @override
  Future<AppUser> register({
    required String nomComplet,
    required String email,
    required String telephone,
    required String password,
  }) async =>
      _openSession(
        await _remote.register(
          nomComplet: nomComplet.trim(),
          email: email.trim().toLowerCase(),
          telephone: telephone,
          password: password,
        ),
      );

  @override
  Future<AppUser?> signInWithGoogle() async {
    final idToken = await _google.getIdToken();
    if (idToken == null) return null;
    return _openSession(await _remote.loginWithGoogle(idToken));
  }

  @override
  Future<AppUser> updatePhone(String telephone) async => (await _remote.updatePhone(telephone)).toEntity();

  @override
  Future<OtpChallenge> sendOtp() async => (await _remote.sendOtp()).toEntity();

  @override
  Future<AppUser> verifyOtp(String code) async => (await _remote.verifyOtp(code)).toEntity();

  @override
  Future<void> requestPasswordReset(String email) => _remote.requestPasswordReset(email.trim().toLowerCase());

  @override
  Future<void> logout() async {
    final refresh = await _tokenStorage.readRefreshToken();
    try {
      if (refresh != null) await _remote.logout(refresh);
    } on ApiException {
      // La déconnexion locale doit réussir même si l'API est injoignable.
    } finally {
      await _tokenStorage.clear();
      await _google.signOut();
    }
  }
}
