import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_service.dart';
import '../dto/connexion_dto.dart';
import '../dto/profil_dto.dart';

/// Appels HTTP d'authentification et de profil. Toute erreur est levée en [ApiException].
abstract interface class AuthRemoteDataSource {
  Future<void> requestCode(String email);

  Future<ConnexionDto> verifyCode({required String email, required String code});

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

  @override
  Future<void> requestCode(String email) =>
      _api.post<void>(ApiEndpoints.otpDemander, body: {'email': email}, parse: (_) {});

  @override
  Future<ConnexionDto> verifyCode({required String email, required String code}) => _api.post(
        ApiEndpoints.otpVerifier,
        body: {'email': email, 'code': code},
        parse: (json) => ConnexionDto.fromJson(ApiService.asMap(json)),
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
