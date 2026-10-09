import '../../../../core/config/demo_account.dart';
import '../../../../core/mock/fake_backend.dart';
import '../../../../core/network/api_exception.dart';
import '../dto/auth_response_dto.dart';
import '../dto/otp_challenge_dto.dart';
import '../dto/user_dto.dart';
import 'auth_remote_data_source.dart';

/// Fausse API d'authentification (`Env.useMockApi`), branchée sur le [FakeBackend] partagé.
/// Respecte le contrat de docs/api/auth.md, erreurs comprises.
///
/// - Compte de démonstration : `demo@kovoit.tg` / `kovoit123`.
/// - Code OTP accepté : `123456`.
class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  FakeAuthRemoteDataSource(this._backend);

  final FakeBackend _backend;

  UserDto _user(int id) => UserDto.fromJson(_backend.userJson(id));

  AuthResponseDto _session(int id) => AuthResponseDto.fromJson(_backend.issueTokens(id));

  @override
  Future<AuthResponseDto> login({required String email, required String password}) async {
    await _backend.wait();
    final account = _backend.userByEmail(email);
    if (account == null || account.password != password) {
      throw const UnauthorizedApiException('Email ou mot de passe incorrect.');
    }
    return _session(account.id);
  }

  @override
  Future<AuthResponseDto> register({
    required String nomComplet,
    required String email,
    required String telephone,
    required String password,
  }) async {
    await _backend.wait();
    final errors = <String, String>{
      if (_backend.userByEmail(email) != null) 'email': 'Un compte existe déjà avec cet e-mail.',
      if (_backend.phoneTaken(telephone)) 'telephone': 'Ce numéro est déjà utilisé.',
    };
    if (errors.isNotEmpty) throw BadRequestApiException('Veuillez corriger le formulaire.', fieldErrors: errors);

    final parts = nomComplet.trim().split(RegExp(r'\s+'));
    final id = _backend.createUser(
      password: password,
      fields: {
        'prenom': parts.first,
        'nom': parts.skip(1).join(' '),
        'email': email.trim().toLowerCase(),
        'telephone': telephone,
      },
    );
    return _session(id);
  }

  @override
  Future<AuthResponseDto> loginWithGoogle(String idToken) async {
    await _backend.wait();
    final existing = _backend.userByEmail(FakeBackend.googleEmail);
    final id = existing?.id ??
        _backend.createUser(
          password: null,
          fields: {'prenom': 'Ama', 'nom': 'Agbeko', 'email': FakeBackend.googleEmail},
        );
    return _session(id);
  }

  @override
  Future<UserDto> me() async {
    await _backend.wait();
    return _user(await _backend.currentUserId());
  }

  @override
  Future<UserDto> updatePhone(String telephone) async {
    await _backend.wait();
    final id = await _backend.currentUserId();
    if (_backend.phoneTaken(telephone, exceptId: id)) {
      throw const BadRequestApiException('Numéro invalide.', fieldErrors: {'telephone': 'Ce numéro est déjà utilisé.'});
    }
    _backend.updateUser(id, {'telephone': telephone, 'telephone_verifie': false});
    return _user(id);
  }

  @override
  Future<UserDto> updateMode(String mode) async {
    await _backend.wait();
    final id = await _backend.currentUserId();
    final user = _backend.userJson(id);
    if (user['statut_compte'] == 'suspendu') {
      throw const ForbiddenApiException('Compte suspendu : changement de mode impossible.');
    }
    if (mode == 'conducteur' && (user['kyc_conducteur'] != 'verifie' || user['vehicule_declare'] != true)) {
      throw const ForbiddenApiException('KYC conducteur validé et véhicule déclaré requis pour le mode conducteur.');
    }
    _backend.updateUser(id, {'mode_actif': mode});
    return _user(id);
  }

  @override
  Future<OtpChallengeDto> sendOtp() async {
    await _backend.wait();
    final telephone = _backend.userJson(await _backend.currentUserId())['telephone'] as String?;
    if (telephone == null) {
      throw const BadRequestApiException('Ajoutez d’abord votre numéro de téléphone.');
    }
    return OtpChallengeDto(telephone: telephone);
  }

  @override
  Future<UserDto> verifyOtp(String code) async {
    await _backend.wait();
    final id = await _backend.currentUserId();
    if (code != DemoAccount.otpCode) {
      throw const BadRequestApiException('Code invalide ou expiré.', fieldErrors: {'code': 'Code invalide ou expiré.'});
    }
    _backend.updateUser(id, {'telephone_verifie': true});
    return _user(id);
  }

  @override
  Future<void> requestPasswordReset(String email) => _backend.wait();

  @override
  Future<void> logout(String refreshToken) => _backend.wait();
}
