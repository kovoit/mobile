import '../../../../core/constants/api_constants.dart';
import '../../../../core/mock/fake_backend.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_service.dart';
import '../dto/kyc_dossier_dto.dart';

abstract interface class KycRemoteDataSource {
  Future<List<KycDossierDto>> fetchDossiers();

  Future<KycDossierDto> uploadPiece({required String type, required String piece, required String filePath});

  Future<KycDossierDto> submit(String type);
}

class ApiKycRemoteDataSource implements KycRemoteDataSource {
  const ApiKycRemoteDataSource(this._api);

  final ApiService _api;

  static KycDossierDto _dossier(Object? json) => KycDossierDto.fromJson(ApiService.asMap(json));

  @override
  Future<List<KycDossierDto>> fetchDossiers() =>
      _api.get(ApiEndpoints.kyc, parse: (json) => ApiService.asList(json).map(_dossier).toList());

  /// JPEG, PNG ou PDF, 5 Mo maximum (vérifié par le backend).
  @override
  Future<KycDossierDto> uploadPiece({required String type, required String piece, required String filePath}) =>
      _api.upload(
        ApiEndpoints.kycPieces(type),
        fields: {'type_piece': piece},
        files: [UploadFile(field: 'fichier', path: filePath)],
        parse: _dossier,
      );

  @override
  Future<KycDossierDto> submit(String type) =>
      _api.post(ApiEndpoints.kycSoumettre(type), parse: _dossier);
}

/// Fausse API KYC (`Env.useMockApi`) branchée sur le [FakeBackend] partagé. Mêmes règles que le backend.
class FakeKycRemoteDataSource implements KycRemoteDataSource {
  FakeKycRemoteDataSource(this._backend);

  final FakeBackend _backend;

  @override
  Future<List<KycDossierDto>> fetchDossiers() async {
    await _backend.wait();
    final id = await _backend.currentUserId();
    return [for (final json in _backend.kycDossiersJson(id)) KycDossierDto.fromJson(json)];
  }

  @override
  Future<KycDossierDto> uploadPiece({required String type, required String piece, required String filePath}) async {
    await _backend.wait();
    final id = await _backend.currentUserId();
    if (!FakeBackend.kycAllowedPieces(type).contains(piece)) {
      throw BadRequestApiException('La pièce « $piece » n\'est pas demandée pour ce dossier.', code: 'DONNEES_INVALIDES');
    }
    final dossier = _backend.kycDossier(id, type);
    if (dossier.statut == 'en_attente' || dossier.statut == 'verifie') {
      throw const ConflictApiException(
        'Ce dossier est en cours de vérification ou déjà vérifié.',
        code: 'DOSSIER_NON_MODIFIABLE',
      );
    }
    dossier.pieces.add(piece);
    return KycDossierDto.fromJson(_backend.kycDossierJson(id, type));
  }

  @override
  Future<KycDossierDto> submit(String type) async {
    await _backend.wait();
    final id = await _backend.currentUserId();
    if (_backend.profilJson(id)['profil_complet'] != true) {
      throw const ForbiddenApiException(
        'Complétez votre profil (nom, prénom, téléphone) avant de soumettre.',
        code: 'PROFIL_INCOMPLET',
      );
    }
    final dossier = _backend.kycDossier(id, type);
    final missing = FakeBackend.kycMissingPieces(type, dossier.pieces);
    if (missing.isNotEmpty) {
      throw BadRequestApiException(
        'Des pièces obligatoires manquent au dossier.',
        code: 'DOSSIER_INCOMPLET',
        details: {'pieces_manquantes': missing},
      );
    }
    dossier
      ..statut = 'en_attente'
      ..motifRejet = null;
    return KycDossierDto.fromJson(_backend.kycDossierJson(id, type));
  }
}
