import '../../../../core/config/demo_account.dart';
import '../../../../core/mock/fake_backend.dart';
import '../../../../core/network/api_exception.dart';
import '../dto/connexion_dto.dart';
import '../dto/profil_dto.dart';
import 'auth_remote_data_source.dart';

/// Fausse API d'authentification (`Env.useMockApi`), branchée sur le [FakeBackend] partagé.
/// Reproduit le backend : connexion par code e-mail, compte créé au premier code valide.
///
/// - Comptes de démonstration : `demo@kovoit.tg` (passager), `conducteur@kovoit.tg` (conducteur).
/// - Code accepté : `123456`. Toute autre adresse crée un nouveau compte (profil à compléter).
class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  FakeAuthRemoteDataSource(this._backend);

  final FakeBackend _backend;

  ProfilDto _profil(int id) => ProfilDto.fromJson(_backend.profilJson(id));

  @override
  Future<void> requestCode(String email) => _backend.wait();

  @override
  Future<ConnexionDto> verifyCode({required String email, required String code}) async {
    await _backend.wait();
    if (code != DemoAccount.otpCode) {
      throw const BadRequestApiException('Code incorrect ou expiré.', code: 'CODE_OTP_INVALIDE');
    }
    final existing = _backend.userByEmail(email);
    final id = existing?.id ?? _backend.createUser(fields: {'email': email});
    return ConnexionDto.fromJson(_backend.issueTokens(id, nouveauCompte: existing == null));
  }

  @override
  Future<ProfilDto> me() async {
    await _backend.wait();
    return _profil(await _backend.currentUserId());
  }

  @override
  Future<ProfilDto> updateProfile({required String prenom, required String nom, required String telephone}) async {
    await _backend.wait();
    final id = await _backend.currentUserId();
    if (_backend.phoneTaken(telephone, exceptId: id)) {
      throw const BadRequestApiException(
        'Données invalides.',
        code: 'DONNEES_INVALIDES',
        fieldErrors: {'telephone': 'Ce numéro est déjà utilisé.'},
      );
    }
    _backend.updateUser(id, {'prenom': prenom, 'nom': nom, 'telephone': telephone});
    return _profil(id);
  }

  @override
  Future<ProfilDto> updateMode(String mode) async {
    await _backend.wait();
    final id = await _backend.currentUserId();
    final user = _backend.userJson(id);
    if (user['statut_compte'] == 'suspendu') {
      throw const ForbiddenApiException('Compte suspendu : changement de mode impossible.');
    }
    if (mode == 'conducteur' && user['kyc_conducteur'] != 'verifie') {
      throw const ForbiddenApiException('Le KYC conducteur doit être vérifié.', code: 'KYC_CONDUCTEUR_REQUIS');
    }
    if (mode == 'conducteur' && user['vehicule_declare'] != true) {
      throw const ForbiddenApiException('Déclarez un véhicule pour passer en mode conducteur.', code: 'VEHICULE_REQUIS');
    }
    _backend.updateUser(id, {'mode_actif': mode});
    return _profil(id);
  }

  @override
  Future<void> logout(String refreshToken) => _backend.wait();
}
