import '../../../../core/config/demo_account.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/token_storage.dart';
import '../dto/auth_response_dto.dart';
import '../dto/otp_challenge_dto.dart';
import '../dto/user_dto.dart';
import 'auth_remote_data_source.dart';

/// Fausse API en mémoire, utilisée tant que le backend n'existe pas (`Env.useMockApi`).
/// Respecte le contrat de docs/api/auth.md, erreurs comprises.
///
/// - Compte de démonstration : `demo@kovoit.tg` / `kovoit123`.
/// - Code OTP accepté : `123456`.
class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  FakeAuthRemoteDataSource(this._tokenStorage, {this.latency = const Duration(milliseconds: 600)}) {
    _users[demoEmail] = const _FakeAccount(
      password: demoPassword,
      user: UserDto(
        id: 1,
        prenom: 'Kodjo',
        nom: 'Mensah',
        email: demoEmail,
        telephone: '+22890123456',
        telephoneVerifie: true,
        kycPassager: 'verifie',
      ),
    );
  }

  static const String demoEmail = DemoAccount.email;
  static const String demoPassword = DemoAccount.password;
  static const String validOtp = DemoAccount.otpCode;
  static const String googleEmail = 'ama.google@gmail.com';

  final TokenStorage _tokenStorage;
  final Duration latency;
  final Map<String, _FakeAccount> _users = {};
  int _nextId = 2;

  Future<void> _wait() => Future<void>.delayed(latency);

  AuthResponseDto _issueTokens(UserDto user) =>
      AuthResponseDto(access: 'mock-access-${user.id}', refresh: 'mock-refresh-${user.id}', user: user);

  /// Retrouve le compte à partir du jeton stocké (le vrai backend lit le header Authorization).
  Future<_FakeAccount> _current() async {
    final token = await _tokenStorage.readAccessToken();
    final id = int.tryParse(token?.replaceFirst('mock-access-', '') ?? '');
    final account = _users.values.where((a) => a.user.id == id).firstOrNull;
    if (account == null) throw const UnauthorizedApiException('Session expirée, veuillez vous reconnecter.');
    return account;
  }

  void _replace(_FakeAccount account, UserDto user) => _users[account.user.email] = account.copyWith(user: user);

  @override
  Future<AuthResponseDto> login({required String email, required String password}) async {
    await _wait();
    final account = _users[email.trim().toLowerCase()];
    if (account == null || account.password != password) {
      throw const UnauthorizedApiException('Email ou mot de passe incorrect.');
    }
    return _issueTokens(account.user);
  }

  @override
  Future<AuthResponseDto> register({
    required String nomComplet,
    required String email,
    required String telephone,
    required String password,
  }) async {
    await _wait();
    final normalizedEmail = email.trim().toLowerCase();
    final errors = <String, String>{
      if (_users.containsKey(normalizedEmail)) 'email': 'Un compte existe déjà avec cet e-mail.',
      if (_users.values.any((a) => a.user.telephone == telephone)) 'telephone': 'Ce numéro est déjà utilisé.',
    };
    if (errors.isNotEmpty) throw BadRequestApiException('Veuillez corriger le formulaire.', fieldErrors: errors);

    final parts = nomComplet.trim().split(RegExp(r'\s+'));
    final user = UserDto(
      id: _nextId++,
      prenom: parts.first,
      nom: parts.skip(1).join(' '),
      email: normalizedEmail,
      telephone: telephone,
    );
    _users[normalizedEmail] = _FakeAccount(password: password, user: user);
    return _issueTokens(user);
  }

  @override
  Future<AuthResponseDto> loginWithGoogle(String idToken) async {
    await _wait();
    final existing = _users[googleEmail];
    if (existing != null) return _issueTokens(existing.user);
    final user = UserDto(id: _nextId++, prenom: 'Ama', nom: 'Agbeko', email: googleEmail);
    _users[googleEmail] = _FakeAccount(password: null, user: user);
    return _issueTokens(user);
  }

  @override
  Future<UserDto> me() async {
    await _wait();
    return (await _current()).user;
  }

  @override
  Future<UserDto> updatePhone(String telephone) async {
    await _wait();
    final account = await _current();
    if (_users.values.any((a) => a.user.telephone == telephone && a.user.id != account.user.id)) {
      throw const BadRequestApiException('Numéro invalide.', fieldErrors: {'telephone': 'Ce numéro est déjà utilisé.'});
    }
    final updated = account.user.copyWithPhone(telephone);
    _replace(account, updated);
    return updated;
  }

  @override
  Future<OtpChallengeDto> sendOtp() async {
    await _wait();
    final account = await _current();
    final telephone = account.user.telephone;
    if (telephone == null) {
      throw const BadRequestApiException('Ajoutez d’abord votre numéro de téléphone.');
    }
    return OtpChallengeDto(telephone: telephone);
  }

  @override
  Future<UserDto> verifyOtp(String code) async {
    await _wait();
    final account = await _current();
    if (code != validOtp) {
      throw const BadRequestApiException('Code invalide ou expiré.', fieldErrors: {'code': 'Code invalide ou expiré.'});
    }
    final updated = account.user.copyWithPhone(account.user.telephone!, verified: true);
    _replace(account, updated);
    return updated;
  }

  @override
  Future<void> requestPasswordReset(String email) => _wait();

  @override
  Future<void> logout(String refreshToken) => _wait();
}

class _FakeAccount {
  const _FakeAccount({required this.password, required this.user});

  /// `null` pour un compte Google.
  final String? password;
  final UserDto user;

  _FakeAccount copyWith({required UserDto user}) => _FakeAccount(password: password, user: user);
}

extension on UserDto {
  UserDto copyWithPhone(String telephone, {bool verified = false}) => UserDto(
        id: id,
        prenom: prenom,
        nom: nom,
        email: email,
        telephone: telephone,
        telephoneVerifie: verified,
        photo: photo,
        modeActif: modeActif,
        statutCompte: statutCompte,
        suspenduJusquAu: suspenduJusquAu,
        kycPassager: kycPassager,
        kycConducteur: kycConducteur,
      );
}
