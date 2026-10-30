import '../../../../core/config/demo_account.dart';
import '../../../../core/mock/fake_backend.dart';
import '../../../../core/network/api_exception.dart';
import '../dto/code_envoye_dto.dart';
import '../dto/connexion_dto.dart';
import '../dto/profil_dto.dart';
import 'auth_remote_data_source.dart';

/// Fausse API d'authentification (`Env.useMockApi`), branchée sur le [FakeBackend] partagé.
/// Reproduit le contrat M-004 (T0) avec le même JSON : inscription, vérification de l'e-mail,
/// connexion par mot de passe, mot de passe oublié. Aucune règle propre au mobile : ce sont
/// celles du serveur, simplifiées.
///
/// - Comptes de démo : `demo@kovoit.tg` (passager), `conducteur@kovoit.tg` (conducteur), mot de
///   passe [DemoAccount.password] ; `ancien@kovoit.tg` sans mot de passe (D-69).
/// - Code reçu « par e-mail » : `123456` (vérification et réinitialisation).
class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  FakeAuthRemoteDataSource(this._backend);

  final FakeBackend _backend;

  static const _verification = 'verification_email';
  static const _reinitialisation = 'reinitialisation';

  ProfilDto _profil(int id) => ProfilDto.fromJson(_backend.profilJson(id));

  static String _normalize(String email) => email.trim().toLowerCase();

  /// Lève l'erreur à partir de l'enveloppe du backend (`{statut, message, reponse: {code, erreurs}}`).
  static Never _fail(int status, String message, String code, [Map<String, List<String>>? erreurs]) =>
      throw ApiException.fromResponse(status, {
        'statut': 'failed',
        'message': message,
        'reponse': {'code': code, 'erreurs': ?erreurs},
      });

  CodeEnvoyeDto _codeEnvoye(String email) => CodeEnvoyeDto.fromJson({
        'email': email,
        'delai_renvoi_s': FakeBackend.otpResendDelay.inSeconds,
      });

  static final _emailFormat = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _phoneFormat = RegExp(r'^\+228[79]\d{7}$');
  static const _commonPasswords = {
    'password', 'motdepasse', 'azertyuiop', 'qwertyuiop', '12345678', '123456789', 'iloveyou', 'kovoit123',
  };

  /// Les 4 validateurs Django (D-79), simplifiés : longueur, mot courant, tout numérique,
  /// ressemblance avec le prénom, le nom ou l'e-mail.
  static List<String> _passwordProblems(String password, {String prenom = '', String nom = '', String email = ''}) {
    final lower = password.toLowerCase();
    bool similar(String attribute) {
      final value = attribute.trim().toLowerCase();
      return value.length >= 3 && (lower.contains(value) || value.contains(lower));
    }

    return [
      if (password.length < 8) 'Ce mot de passe est trop court. Il doit contenir au minimum 8 caractères.',
      if (_commonPasswords.contains(lower)) 'Ce mot de passe est trop courant.',
      if (RegExp(r'^\d+$').hasMatch(password)) 'Ce mot de passe est entièrement numérique.',
      if (similar(prenom)) 'Le mot de passe est trop semblable au champ « prénom ».'
      else if (similar(nom)) 'Le mot de passe est trop semblable au champ « nom ».'
      else if (similar(email.split('@').first)) 'Le mot de passe est trop semblable au champ « adresse e-mail ».',
    ];
  }

  static void _checkPassword(String password, {String prenom = '', String nom = '', String email = ''}) {
    final problems = _passwordProblems(password, prenom: prenom, nom: nom, email: email);
    if (problems.isNotEmpty) {
      _fail(400, 'Mot de passe trop faible.', 'MOT_DE_PASSE_FAIBLE', {'mot_de_passe': problems});
    }
  }

  @override
  Future<CodeEnvoyeDto> register({
    required String prenom,
    required String nom,
    required String email,
    required String telephone,
    required String motDePasse,
    required bool cguAcceptees,
  }) async {
    await _backend.wait();
    final normalized = _normalize(email);
    const obligatoire = 'Ce champ est obligatoire.';
    final invalid = <String, List<String>>{
      if (!cguAcceptees) 'cgu_acceptees': ['Vous devez accepter les conditions d’utilisation.'],
      if (prenom.trim().isEmpty) 'prenom': [obligatoire],
      if (prenom.length > 100) 'prenom': ['Assurez-vous que ce champ comporte au plus 100 caractères.'],
      if (nom.trim().isEmpty) 'nom': [obligatoire],
      if (nom.length > 100) 'nom': ['Assurez-vous que ce champ comporte au plus 100 caractères.'],
      if (!_emailFormat.hasMatch(normalized)) 'email': ['Saisissez une adresse e-mail valide.'],
      if (motDePasse.isEmpty) 'mot_de_passe': [obligatoire],
      if (motDePasse.length > 128) 'mot_de_passe': ['Assurez-vous que ce champ comporte au plus 128 caractères.'],
    };
    if (invalid.isNotEmpty) _fail(400, 'Les données envoyées sont invalides.', 'DONNEES_INVALIDES', invalid);
    if (!_phoneFormat.hasMatch(telephone)) {
      _fail(400, 'Numéro de téléphone invalide.', 'TELEPHONE_INVALIDE', {
        'telephone': ['Saisissez un numéro mobile togolais (8 chiffres commençant par 7 ou 9).'],
      });
    }
    _checkPassword(motDePasse, prenom: prenom, nom: nom, email: normalized);
    // D-66 : le téléphone n'est pas unique ; D-75 : l'adresse l'est (vérifiée ou non).
    if (_backend.userByEmail(normalized) != null) {
      _fail(409, 'Un compte existe déjà avec cette adresse e-mail.', 'EMAIL_DEJA_UTILISE', {
        'email': ['Un compte existe déjà avec cette adresse e-mail.'],
      });
    }
    _backend.createUser(
      password: motDePasse,
      fields: {
        'prenom': prenom.trim(),
        'nom': nom.trim(),
        'email': normalized,
        'telephone': telephone,
        'email_verifie': false,
        'cgu_acceptees': true,
      },
    );
    _backend.sendCode(_verification, normalized);
    return _codeEnvoye(normalized);
  }

  @override
  Future<ConnexionDto> verifyEmail({required String email, required String code}) async {
    await _backend.wait();
    final normalized = _normalize(email);
    final user = _backend.userByEmail(normalized);
    final pending = _backend.codesSent.containsKey('$_verification:$normalized');
    if (code != DemoAccount.otpCode || user == null || user.fields['email_verifie'] == true || !pending) {
      _fail(400, 'Code invalide ou expiré.', 'CODE_OTP_INVALIDE');
    }
    _backend.codesSent.remove('$_verification:$normalized');
    _backend.updateUser(user.id, {'email_verifie': true});
    return ConnexionDto.fromJson(_backend.issueTokens(user.id, nouveauCompte: true));
  }

  @override
  Future<CodeEnvoyeDto> resendVerificationCode(String email) async {
    await _backend.wait();
    final normalized = _normalize(email);
    final user = _backend.userByEmail(normalized);
    // Adresse inconnue ou déjà vérifiée : même réponse, rien n'est envoyé (D-75). Compte non vérifié
    // dans le délai de renvoi ou au plafond horaire : 429 `TROP_DE_REQUETES` (contrat M-004).
    if (user != null && user.fields['email_verifie'] != true) {
      _backend.sendCode(_verification, normalized, strict: true);
    }
    return _codeEnvoye(normalized);
  }

  @override
  Future<ConnexionDto> login({required String email, required String motDePasse}) async {
    await _backend.wait();
    _backend.countLoginRequest();
    final normalized = _normalize(email);
    final user = _backend.userByEmail(normalized);
    // Inconnu, supprimé, sans mot de passe utilisable ou mauvais mot de passe : même 401 (D-74).
    if (user == null || user.password == null || user.password != motDePasse) {
      _fail(401, 'Email ou mot de passe incorrect.', 'IDENTIFIANTS_INVALIDES');
    }
    if (user.fields['email_verifie'] != true) {
      // D-73 : nouveau code hors délai et sous le plafond, sinon même 403 sans envoi.
      try {
        _backend.sendCode(_verification, normalized);
      } on TooManyAttemptsApiException {
        // plafond atteint : aucun envoi, réponse inchangée
      }
      _fail(403, 'Adresse e-mail non vérifiée. Saisissez le code reçu par e-mail.', 'EMAIL_NON_VERIFIE');
    }
    // Compte suspendu : connexion acceptée, l'alerte COMPTE_SUSPENDU est dans le profil (D-74).
    return ConnexionDto.fromJson(_backend.issueTokens(user.id));
  }

  @override
  Future<CodeEnvoyeDto> requestPasswordReset(String email) async {
    await _backend.wait();
    final normalized = _normalize(email);
    // Adresse inconnue : même réponse, aucun code (pas de compte `is_staff` dans le faux serveur).
    // Compte éligible dans le délai de renvoi ou au plafond horaire : 429 `TROP_DE_REQUETES`.
    if (_backend.userByEmail(normalized) != null) {
      _backend.sendCode(_reinitialisation, normalized, strict: true);
    }
    return _codeEnvoye(normalized);
  }

  @override
  Future<void> resetPassword({required String email, required String code, required String motDePasse}) async {
    await _backend.wait();
    final normalized = _normalize(email);
    final user = _backend.userByEmail(normalized);
    // Contrôlé avant le code : un mot de passe refusé ne consomme pas le code.
    _checkPassword(
      motDePasse,
      prenom: user?.fields['prenom'] as String? ?? '',
      nom: user?.fields['nom'] as String? ?? '',
      email: normalized,
    );
    final pending = _backend.codesSent.containsKey('$_reinitialisation:$normalized');
    if (code != DemoAccount.otpCode || user == null || !pending) {
      _fail(400, 'Code invalide ou expiré.', 'CODE_OTP_INVALIDE');
    }
    _backend.codesSent.remove('$_reinitialisation:$normalized');
    user.password = motDePasse;
    // D-77 : une réinitialisation réussie vérifie l'adresse.
    _backend.updateUser(user.id, {'email_verifie': true});
  }

  @override
  Future<ProfilDto> me() async {
    await _backend.wait();
    return _profil(await _backend.currentUserId());
  }

  @override
  Future<ProfilDto> acceptTerms() async {
    await _backend.wait();
    final id = await _backend.currentUserId();
    _backend.updateUser(id, {'cgu_acceptees': true});
    return _profil(id);
  }

  @override
  Future<ProfilDto> updateProfile({
    required String prenom,
    required String nom,
    required String telephone,
    bool acceptCgu = false,
  }) async {
    await _backend.wait();
    final id = await _backend.currentUserId();
    // D-66 : deux comptes peuvent partager un numéro.
    _backend.updateUser(id, {
      'prenom': prenom,
      'nom': nom,
      'telephone': telephone,
      if (acceptCgu) 'cgu_acceptees': true,
    });
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

  /// Extensions acceptées par l'`ImageField` du backend (les plus courantes sur Android).
  static const _imageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'heic', 'heif'};

  int _photoCount = 0;

  /// Comme le backend : un fichier qui n'est pas une image est refusé (400, `erreurs.photo`) ;
  /// sinon le profil est renvoyé avec le chemin **relatif** de la nouvelle photo (`/media/…`), comme
  /// le vrai backend (décision Q1 révisée) : `ProfilDto` le complète avec l'origine de l'API. Ce
  /// chemin ne pointe vers aucun fichier : l'avatar garde les initiales en mode démo.
  @override
  Future<ProfilDto> updatePhoto(String filePath) async {
    await _backend.wait();
    final id = await _backend.currentUserId();
    final extension = filePath.contains('.') ? filePath.split('.').last.toLowerCase() : '';
    if (!_imageExtensions.contains(extension)) {
      throw const BadRequestApiException(
        'Les données envoyées sont invalides.',
        code: 'DONNEES_INVALIDES',
        fieldErrors: {
          'photo': "Transférez une image valide. Le fichier que vous avez transféré n'est pas une image, "
              'ou il est corrompu.',
        },
      );
    }
    _photoCount++;
    _backend.updateUser(id, {'photo': '/media/photos_profil/profil-$id-$_photoCount.jpg'});
    return _profil(id);
  }

  @override
  Future<void> logout(String refreshToken) => _backend.wait();

  /// Mêmes règles que le backend (simplifiées) : confirmation, aucune réservation en cours.
  @override
  Future<void> deleteAccount(String confirmation) async {
    await _backend.wait();
    if (confirmation.trim().toUpperCase() != 'SUPPRIMER') {
      throw const ForbiddenApiException('Saisissez SUPPRIMER pour confirmer la suppression.');
    }
    final id = await _backend.currentUserId();
    const closed = {'refusee', 'annulee', 'absent', 'cloturee'};
    if (_backend.bookings.values.any((b) => b['passager_id'] == id && !closed.contains(b['statut']))) {
      throw const ConflictApiException(
        'Vous avez une réservation en cours : annulez-la ou attendez sa clôture.',
        code: 'SUPPRESSION_IMPOSSIBLE',
      );
    }
    _backend.deleteUser(id);
  }
}
