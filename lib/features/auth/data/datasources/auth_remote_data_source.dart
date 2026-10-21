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

  Future<ProfilDto> updateProfile({required String prenom, required String nom, required String telephone});

  /// `passager` | `conducteur`. 403 si le mode conducteur n'est pas autorisé.
  Future<ProfilDto> updateMode(String mode);

  Future<void> logout(String refreshToken);
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
  Future<ProfilDto> updateProfile({required String prenom, required String nom, required String telephone}) =>
      _api.patch(ApiEndpoints.moi, body: {'prenom': prenom, 'nom': nom, 'telephone': telephone}, parse: _profil);

  @override
  Future<ProfilDto> updateMode(String mode) =>
      _api.patch(ApiEndpoints.moiMode, body: {'mode_actif': mode}, parse: _profil);

  @override
  Future<void> logout(String refreshToken) =>
      _api.post<void>(ApiEndpoints.deconnexion, body: {'refresh': refreshToken}, parse: (_) {});
}
