import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_service.dart';
import '../dto/code_envoye_dto.dart';
import '../dto/connexion_dto.dart';
import '../dto/profil_dto.dart';

/// Noms des champs envoyés aux routes `auth/…` (contrat M-004 T0).
abstract final class AuthFields {
  static const email = 'email';
  static const motDePasse = 'mot_de_passe';
  static const prenom = 'prenom';
  static const nom = 'nom';
  static const telephone = 'telephone';
  static const cguAcceptees = 'cgu_acceptees';
  static const code = 'code';
}

/// Appels HTTP d'authentification et de profil. Toute erreur est levée en [ApiException].
/// Le mot de passe ne fait que transiter dans le corps de la requête (jamais journalisé).
abstract interface class AuthRemoteDataSource {
  /// `POST auth/inscription/` → 201 `CODE_ENVOYE`, aucun jeton.
  Future<CodeEnvoyeDto> register({
    required String prenom,
    required String nom,
    required String email,
    required String telephone,
    required String motDePasse,
    required bool cguAcceptees,
  });

  /// `POST auth/inscription/verifier/` → `SESSION` (`nouveau_compte` vrai).
  Future<ConnexionDto> verifyEmail({required String email, required String code});

  /// `POST auth/inscription/renvoyer-code/` → `CODE_ENVOYE`.
  Future<CodeEnvoyeDto> resendVerificationCode(String email);

  /// `POST auth/connexion/` → `SESSION` (`nouveau_compte` faux).
  Future<ConnexionDto> login({required String email, required String motDePasse});

  /// `POST auth/mot-de-passe/oublie/` → `CODE_ENVOYE`.
  Future<CodeEnvoyeDto> requestPasswordReset(String email);

  /// `POST auth/mot-de-passe/reinitialiser/` → `reponse` null.
  Future<void> resetPassword({required String email, required String code, required String motDePasse});

  Future<ProfilDto> me();

  Future<ProfilDto> updateProfile({
    required String prenom,
    required String nom,
    required String telephone,
    bool acceptCgu = false,
  });

  /// Accepte les conditions d'utilisation en vigueur (`accepter_cgu`).
  Future<ProfilDto> acceptTerms();

  /// `passager` | `conducteur`. 403 si le mode conducteur n'est pas autorisé.
  Future<ProfilDto> updateMode(String mode);

  /// `PATCH /moi/` en multipart, champ `photo` (contrat C3). 400 `DONNEES_INVALIDES` avec
  /// `erreurs.photo` si le fichier n'est pas une image acceptée.
  Future<ProfilDto> updatePhoto(String filePath);

  Future<void> logout(String refreshToken);

  /// Compte anonymisé côté serveur. `ConflictApiException` (SUPPRESSION_IMPOSSIBLE) avec les
  /// raisons si une réservation, un trajet ou de l'argent est en cours.
  Future<void> deleteAccount(String confirmation);
}

class ApiAuthRemoteDataSource implements AuthRemoteDataSource {
  const ApiAuthRemoteDataSource(this._api);

  final ApiService _api;

  static ProfilDto _profil(Object? json) => ProfilDto.fromJson(ApiService.asMap(json));

  static ConnexionDto _session(Object? json) => ConnexionDto.fromJson(ApiService.asMap(json));

  static CodeEnvoyeDto _codeEnvoye(Object? json) => CodeEnvoyeDto.fromJson(ApiService.asMap(json));

  @override
  Future<CodeEnvoyeDto> register({
    required String prenom,
    required String nom,
    required String email,
    required String telephone,
    required String motDePasse,
    required bool cguAcceptees,
  }) =>
      _api.post(
        ApiEndpoints.inscription,
        body: {
          AuthFields.prenom: prenom,
          AuthFields.nom: nom,
          AuthFields.email: email,
          AuthFields.telephone: telephone,
          AuthFields.motDePasse: motDePasse,
          AuthFields.cguAcceptees: cguAcceptees,
        },
        parse: _codeEnvoye,
      );

  @override
  Future<ConnexionDto> verifyEmail({required String email, required String code}) => _api.post(
        ApiEndpoints.inscriptionVerifier,
        body: {AuthFields.email: email, AuthFields.code: code},
        parse: _session,
      );

  @override
  Future<CodeEnvoyeDto> resendVerificationCode(String email) =>
      _api.post(ApiEndpoints.inscriptionRenvoyerCode, body: {AuthFields.email: email}, parse: _codeEnvoye);

  @override
  Future<ConnexionDto> login({required String email, required String motDePasse}) => _api.post(
        ApiEndpoints.connexion,
        body: {AuthFields.email: email, AuthFields.motDePasse: motDePasse},
        parse: _session,
      );

  @override
  Future<CodeEnvoyeDto> requestPasswordReset(String email) =>
      _api.post(ApiEndpoints.motDePasseOublie, body: {AuthFields.email: email}, parse: _codeEnvoye);

  @override
  Future<void> resetPassword({required String email, required String code, required String motDePasse}) =>
      _api.post<void>(
        ApiEndpoints.motDePasseReinitialiser,
        body: {AuthFields.email: email, AuthFields.code: code, AuthFields.motDePasse: motDePasse},
        parse: (_) {},
      );

  @override
  Future<ProfilDto> me() => _api.get(ApiEndpoints.moi, parse: _profil);

  @override
  Future<ProfilDto> updateProfile({
    required String prenom,
    required String nom,
    required String telephone,
    bool acceptCgu = false,
  }) =>
      _api.patch(
        ApiEndpoints.moi,
        body: {'prenom': prenom, 'nom': nom, 'telephone': telephone, if (acceptCgu) 'accepter_cgu': true},
        parse: _profil,
      );

  @override
  Future<ProfilDto> acceptTerms() => _api.patch(ApiEndpoints.moi, body: {'accepter_cgu': true}, parse: _profil);

  @override
  Future<ProfilDto> updateMode(String mode) =>
      _api.patch(ApiEndpoints.moiMode, body: {'mode_actif': mode}, parse: _profil);

  @override
  Future<ProfilDto> updatePhoto(String filePath) => _api.upload(
        ApiEndpoints.moi,
        method: 'PATCH',
        files: [UploadFile(field: 'photo', path: filePath)],
        parse: _profil,
      );

  @override
  Future<void> deleteAccount(String confirmation) =>
      _api.post<void>(ApiEndpoints.moiSupprimer, body: {'confirmation': confirmation}, parse: (_) {});

  @override
  Future<void> logout(String refreshToken) =>
      _api.post<void>(ApiEndpoints.deconnexion, body: {'refresh': refreshToken}, parse: (_) {});
}
